REFINE_SERVER = "http://127.0.0.1:3333"

get '/' do
  haml :index
end

post '/upload' do
  time = Time.now.to_i.to_s
  headers "Content-Disposition" => "attachment;filename=#{time}.csv", "Content-Type" => "application/octet-stream"
  unless params['project-file'] &&
         (tmpfile = params['project-file'][:tempfile]) &&
         (name = params['project-file'][:filename])
    @error = "No file selected"
    return haml :index
  end
  
  data = File.join(Dir.pwd, time)
  json = File.join(Dir.pwd, "#{time}.json")
  
  File.open(data, "wb") do |f| 
    while block = tmpfile.read(65536)
      f.write(block)
    end
  end
  File.open(json, "wb") { |f| f.write(params['history-json'])}
  
  prj = Refine.new(time, data, REFINE_SERVER)
  prj.apply_operations(json)
  csv = prj.export_rows('csv')
  
  prj.delete_project
  [data, json].each {|f| File.delete(f)}
  
  csv
end