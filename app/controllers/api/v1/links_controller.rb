require 'rqrcode'

class Api::V1::LinksController < ApplicationController
  def create
    url = params[:url]
    return render json: { error: 'URL is required' }, status: :bad_request unless url.present?

    short_code = SecureRandom.alphanumeric(6)

    link = Link.new(
      original_url: url,
      short_code: short_code,
      click_count: 0,
      expires_at: params[:expires_at]
    )

    # Optional password protection
    link.password = params[:password] if params[:password].present?

    if link.save
      render json: {
        short_url: request.base_url + "/api/v1/#{link.short_code}",
        stats_url: request.base_url + "/api/v1/#{link.short_code}/stats",
        expires_at: link.expires_at,
        password_protected: link.password_digest.present?
      }
    else
      render json: { error: link.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def redirect
    link = Link.find_by(short_code: params[:short_code])
    return render json: { error: 'Not found' }, status: :not_found unless link

    # Check expiration
    if link.expires_at.present? && Time.current > link.expires_at
      return render json: { error: 'Link has expired' }, status: :gone
    end

    # Check password
    if link.password_digest.present?
      if params[:password].blank?
        return render json: { error: 'Password required' }, status: :unauthorized
      end

      unless link.authenticate(params[:password])
        return render json: { error: 'Invalid password' }, status: :unauthorized
      end
    end

    link.increment!(:click_count)

    Click.create!(
      link: link,
      ip: request.remote_ip,
      referrer: request.referer,
      user_agent: request.user_agent,
      city: fetch_location(request.remote_ip)[:city],
      region: fetch_location(request.remote_ip)[:region],
      country: fetch_location(request.remote_ip)[:country],
      lat: fetch_location(request.remote_ip)[:lat],
      lon: fetch_location(request.remote_ip)[:lon]
    )

    redirect_to link.original_url, allow_other_host: true
  end

  def fetch_location(ip)
    ip = "8.8.8.8" if ip == "::1" || ip == "127.0.0.1"  # Use Google's public DNS for testing

    begin
      res = HTTParty.get("https://ip-api.com/json/#{ip}")
      return {
        city: res["city"],
        region: res["regionName"],
        country: res["country"],
        lat: res["lat"],
        lon: res["lon"]
      }
    rescue
      {}
    end
  end

  def stats
    link = Link.find_by(short_code: params[:short_code])
    return render json: { error: 'Not found' }, status: :not_found unless link
    return unless authenticate_link(link)

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
          location: "#{c.city}, #{c.region}, #{c.country}",
          lat: c.lat,
          lon: c.lon,
          time: c.created_at
        }
      end
    }
  end 

  def qr_code
    link = Link.find_by(short_code: params[:short_code])
    return render plain: "Not found", status: :not_found unless link
    return unless authenticate_link(link)

    begin
      qr = RQRCode::QRCode.new(request.original_url)

      png = qr.as_png(
        bit_depth: 1,
        border_modules: 4,
        color_mode: ChunkyPNG::COLOR_GRAYSCALE,
        color: 'black',
        file: nil,
        fill: 'white',
        module_px_size: 6,
        resize_exactly_to: false,
        size: 240
      )

      send_data png.to_s, type: 'image/png', disposition: 'inline'
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def authenticate_link(link)
    if link.password_digest.present?
      if params[:password].blank?
        render json: { error: 'Password required' }, status: :unauthorized and return false
      end

      unless link.authenticate(params[:password])
        render json: { error: 'Invalid password' }, status: :unauthorized and return false
      end
    end
    true
  end
end

