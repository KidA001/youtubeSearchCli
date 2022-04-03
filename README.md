# Description
This script was originally created to help find youtube videos that have little to no views. Youtube's web search and API does not make it possible to sort videos from lowest to highest view count. This script allows you to set a maximum number of views (including 0) and will return matching results.

Because we cannot sort by lowest to highest, this script needs to iterate through *all* results for your search query and will filter by the view count parameters you've set. It's slow. You can get a free developer API key from Google which has a daily limit of 10,000 requests.

## Setup
- Install Ruby 2.7.1 or higher `\curl -sSL https://get.rvm.io | bash -s stable`
- Install HTTParty `gem install httparty`
- Get a [Google API Key](https://console.cloud.google.com/apis/credentials)
- Enable the [YouTube Data API](https://console.cloud.google.com/marketplace/product/google/youtube.googleapis.com)
- Add your API key to line 15 `DEVELOPER_KEY='xxxxxxxxxxxxxxxxxxxxxxx'`
- Run the script in your terminal with `ruby youtube_search.rb`
