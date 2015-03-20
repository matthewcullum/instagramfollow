task :s do
  desc 'Starts development server'
  exec 'foreman start -f Procfile.dev'
end

