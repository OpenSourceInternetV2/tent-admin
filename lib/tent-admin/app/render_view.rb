require 'erb'

module TentAdmin
  class App
    class RenderView < Middleware

      class TempalteContext
        AssetNotFoundError = AssetServer::SprocketsHelpers::AssetNotFoundError

        attr_reader :env
        def initialize(env, renderer, &block)
          @env, @renderer, @block = env, renderer, block
        end

        def erb(view_name)
          @renderer.erb(view_name, binding)
        end

        def block_given?
          !@block.nil? && @block.respond_to?(:call)
        end

        def yield
          @block.call(self)
        end

        def sprockets_environment
          AssetServer.sprockets_environment
        end

        def asset_path(source)
          asset = sprockets_environment.find_asset(source)
          raise AssetNotFoundError.new("#{source.inspect} does not exist within #{sprockets_environment.paths.inspect}!") unless asset
          full_path("/assets/#{asset.digest_path}")
        end

        def path_prefix
          ENV['PATH_PREFIX'].to_s
        end

        def full_path(path)
          "#{path_prefix}/#{path}".gsub(%r{/+}, '/')
        end

        def nav_selected_class(path)
          env['REQUEST_PATH'] == full_path(path) ? 'active' : ''
        end
      end

      def initialize(app, options={})
        super

        @view_root = @options[:view_root] || File.expand_path('../../../views', __FILE__) # lib/views
      end

      def action(env)
        return env unless env['response.view']

        status = env['response.status'] || 200
        headers = { 'Content-Type' => 'text/html' }.merge(env['response.headers'] || Hash.new)
        body = render(env)

        unless body
          status = 404
          body = "View not found: #{env['response.view'].inspect}"
        end

        [status, headers, [body]]
      end

      def erb(view_name, binding, &block)
        view_path = "#{@view_root}/#{view_name}.erb"
        return unless File.exists?(view_path)

        template = ERB.new(File.read(view_path))
        template.result(binding)
      end

      private

      def render(env)
        if env['response.layout']
          layout = env['response.layout']
          view = env['response.view']
          block = proc { |binding| erb(view, template_binding(env)) }
          erb(layout, template_binding(env, &block))
        else
          erb(env['response.view'], template_binding(env))
        end
      end

      def template_binding(env, &block)
        TempalteContext.new(env, self, &block).instance_eval { binding }
      end

    end
  end
end
