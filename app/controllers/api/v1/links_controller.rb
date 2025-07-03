class Api::V1::LinksController < ApplicationController
  def create
    url = params[:url]
    return render json: { error: 'URL is required' }, status: :bad_request unless url.present?

    short_code = SecureRandom.alphanumeric(6)
    link = Link.create!(original_url: url, short_code: short_code, click_count: 0)

    render json: {
      short_url: request.base_url + "/api/v1/#{link.short_code}",
      stats_url: request.base_url + "/api/v1/#{link.short_code}/stats"
    }
  end

  def redirect
    link = Link.find_by(short_code: params[:short_code])
    return render json: { error: 'Not found' }, status: :not_found unless link

    link.increment!(:click_count)

    Click.create!(
      link: link,
      ip: request.remote_ip,
      referrer: request.referer,
      user_agent: request.user_agent
    )

    redirect_to link.original_url, allow_other_host: true
  end

  def stats
    link = Link.find_by(short_code: params[:short_code])
    return render json: { error: 'Not found' }, status: :not_found unless link

    clicks = link.clicks.order(created_at: :desc).limit(20)

    render json: {
      original_url: link.original_url,
      short_code: link.short_code,
      total_clicks: link.click_count,
      recent_clicks: clicks.map do |c|
        {
          ip: c.ip,
          referrer: c.referrer,
          user_agent: c.user_agent,
          time: c.created_at
        }
      end
    }
  end
end

