#!/usr/bin/env ruby
# Requires Ruby 2.7 or higher
# Before running make sure you have these libraries installed:
# gem install httparty

# To Run:
# From your terminal go to the directory where this file lives
# enter `ruby youtube_search.rb` and follow the prompts ¯\_(ツ)_/¯
# Edit variables below as needed

require 'httparty'
require 'csv'

class YouTube
  DEVELOPER_KEY = 'INSERT G00GL3 DEVELOPER KEY HERE'
  MAX_VIEW_COUNT = 100
  class InvalidResponse < StandardError; end

  attr_reader :all_results, :search_term, :after_date, :before_date

  def initialize(search_term: , before_date: nil, after_date: nil)
    @search_term = search_term
    @before_date = append_date(before_date)
    @after_date = append_date(after_date)
    @search_url = 'https://www.googleapis.com/youtube/v3/search'
    @statistics_url = 'https://www.googleapis.com/youtube/v3/videos?part=statistics'
    @all_results = []
  end


  def get_all(next_page_token = nil)
    puts 'Searching for results...' if next_page_token.nil?
    puts "Searching next page: #{next_page_token}" if !next_page_token.nil?
    results = search(next_page_token)

    results['items'].each do |result|
      # Processing for each YouTube video happens here
      # We get the stats, check the view count and add it to our list of all_results
      # if it's below the max view count
      statistics = get_statistics(result)
      next_page_token = results['nextPageToken']
      view_count = statistics.dig('viewCount')
      next if exceeds_max_view_count?(view_count)

      @all_results << format_result(result, statistics)
    end
      # Recursively calls this method again if another page exists until all pages have been processed
      puts "Current result count: #{@all_results.count}"
      get_all(next_page_token) unless next_page_token.nil?
  end

  private

  def exceeds_max_view_count?(view_count)
    return true if view_count.nil?

    view_count.to_i > MAX_VIEW_COUNT
  end

  def search(next_page_token = nil)
    # Search parameters for youtube Search endpoint
    # Docs: https://developers.google.com/youtube/v3/docs/search/list
    params = {
      q: @search_term,
      maxResults: 50,
      pageToken: next_page_token,
      key: DEVELOPER_KEY,
      part: 'snippet',
      type: 'video',
      safeSearch: 'none'
    }

    # Adds before/after dates if provided
    params.merge!(publishedAfter: @after_date) unless @after_date.nil?
    params.merge!(publishedBefore: @before_date) unless @before_date.nil?

    response = HTTParty.get(@search_url, query: params)
    validate!(response)
  end

  def validate!(response)
    return response if response.success?

    err_msg = results&.dig('error', 'message') || 'Invalid response from YouTube API'
    raise InvalidResponse, err_msg
  end

  def get_statistics(result)
    id = result['id']['videoId']
    params = { key: DEVELOPER_KEY, id: id}
    result = HTTParty.get(@statistics_url, query: params)
    validate!(result)
    return nil if result['items'].nil? || result['items'][0].nil?

    result['items'][0].dig('statistics')
  end

  def format_result(result, statistics)
    {
      title: result['snippet']['title'],
      publish_date: result['snippet']['publishedAt'],
      view_count: statistics['viewCount'].to_i,
      like_count: statistics['likeCount'],
      dislike_count: statistics['dislikeCount'],
      favorite_count: statistics['favoriteCount'],
      comment_count: statistics['commentCount'],
      url: "https://www.youtube.com/watch?v=#{result['id']['videoId']}"
    }
  end

  def append_date(date)
    return if date.nil?
    # Dates are passed by the user as "YYYY-MM-DD" but need to be
    # appened to "YYYY-MM-DDT00:00:00Z"
    "#{date}T00:00:00Z"
  end
end

class UserInteraction

  def initialize
    @after_date = nil
    @before_date = nil
    @search_term = nil
  end

  def run
    get_search_term
    get_after_date
    get_before_date
    begin_search
    summarize
    save_to_csv
  rescue => e
    puts 'Error:'
    puts e
    summarize(error: true)
    save_to_csv
  end

  private

  def save_to_csv
    return if @youtube.all_results.empty?

    title = Time.now.strftime('%Y-%m-%d %H%M%S')
    headers = @youtube.all_results.first.keys

    CSV.open("#{title}.csv", "w", headers: headers, write_headers: true) do |csv|
      @youtube.all_results.each do |result|
        csv << result.values
      end
    end
    puts "\nResults saved to: #{title}.csv"
  end

  def summarize(error: false)
    error ? puts('Finished with errors!') : puts('Finished!')
    puts '-------Results-------'
    puts "Search Term: #{@youtube.search_term}"
    puts "After Date: #{@youtube.after_date}" if @youtube.after_date
    puts "Before Date: #{@youtube.before_date}" if @youtube.before_date
    puts "Number of results: #{@youtube.all_results.count}"
  end

  def begin_search
    @youtube = YouTube.new(search_term: @search_term, before_date: @before_date, after_date: @after_date)
    @youtube.get_all
  end

  def get_search_term
    print 'Enter the search term: '
    @search_term = gets.chomp.downcase
  end

  def get_after_date
    print 'Would you like to search for results After a certain date? (Enter Y or N): '
    choice = parse_choice(gets.chomp)
    if choice
      puts 'Enter the after date in YYYY-MM-DD format:'
      @after_date = gets.chomp
    end
  end

  def get_before_date
    print 'Would you like to search for results Before a certain date? (Enter Y or N): '
    choice = parse_choice(gets.chomp)
    if choice
      puts 'Enter the after date in YYYY-MM-DD format:'
      @before_date = gets.chomp
    end
  end

  def parse_choice(choice)
    if choice == 'y'
      true
    elsif choice  == 'n'
      false
    else
      raise StandardError, 'Invalid Choice'
    end
  end
end

UserInteraction.new.run
