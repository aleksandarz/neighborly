class ChannelDecorator < Draper::Decorator
  decorates :channel

  def image_url
    "channels/#{source.permalink}.png"
  end

  def display_facebook
    last_fragment(source.facebook)
  end

  def display_twitter
    "@#{last_fragment(source.twitter)}"
  end

  def display_website
    source.website.gsub(/https?:\/\//i, '')
  end

  def display_video_embed_url
    "//#{source.video_embed_url}?title=0&byline=0&portrait=0&autoplay=0&color=ffffff&badge=0&modestbranding=1&showinfo=0&border=0&controls=2".gsub('http://', '') if source.video_embed_url
  end

  private
  def last_fragment(uri)
    uri.split("/").last
  end
end
