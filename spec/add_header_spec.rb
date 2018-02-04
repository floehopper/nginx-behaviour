require 'spec_helper'
require 'tempfile'
require 'net/http'

RSpec.describe 'add_header' do
  around do |example|
    file = Tempfile.new
    file.write(config)
    file.close
    `sudo cp #{file.path} /etc/nginx/sites-available/#{hostname}`
    File.delete(file.path)
    `sudo ln --symbolic --force /etc/nginx/sites-available/#{hostname} /etc/nginx/sites-enabled/`

    `sudo systemctl stop nginx.service`
    while (`systemctl is-active nginx.service` == 'active') do; end
    `sudo systemctl start nginx.service`
    while (`systemctl is-active nginx.service` == 'inactive') do; end

    example.run

    `sudo rm /etc/nginx/sites-enabled/#{hostname}`
    `sudo rm /etc/nginx/sites-available/#{hostname}`

    `sudo systemctl stop nginx.service`
    while (`systemctl is-active nginx.service` == 'active') do; end
    `sudo systemctl start nginx.service`
    while (`systemctl is-active nginx.service` == 'inactive') do; end
  end

  let(:hostname) { 'add_header.test' }
  let(:header_key) { 'X-Custom-Header' }
  let(:header_value) { '123' }

  let(:config) {
    %[
      server {
        server_name #{hostname};
        add_header #{header_key} #{header_value};
        location / {
          return 200 OK;
        }
      }
    ]
  }

  it 'adds HTTP header to response' do
    uri = URI('http://localhost')
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri)
      request['Host'] = hostname
      response = http.request(request)
      expect(response[header_key]).to eq(header_value)
    end
  end
end
