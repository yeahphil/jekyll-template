require 'yaml'

class AutoJekyll
  def call(env)
    `jekyll` if needs_regeneration?

    # append 'index.html' to naked path endings
    env['PATH_INFO'] += "index.html" if env['PATH_INFO'][-1..-1] == '/'

    Rack::File.new('_site').call(env)
  end

  def needs_regeneration?
    return true if !File.exist?('_site')

    parent_dir = File.dirname(__FILE__)
    mtime = File.mtime('_site')
    exclusions = (File.exist?('_config.yml') ? YAML.load('_config.yml') : {})['exclude'] || []
    exclusions << '_site'

    return changed?(parent_dir, mtime, exclusions)
  end

  def changed?(path, mtime, exclusions)
    Dir.foreach(path) do |entry|
      next if !exclusions || exclusions.include?(entry) || entry == '.' || entry == '..'

      full = File.join(path, entry)
      # puts full
      if File.directory?(full)
        return true if changed?(full, mtime, exclusions)
      else
        result = File.mtime(full) > mtime
        # puts "#{full}: #{result}"
        return true if result
      end
    end
  end
end

run AutoJekyll.new