module EnvManager
  module ActionViewHtmlTemplateRenderPatch
    module HtmlRenderAcceptsBlock
      def render(*args, &block)
        super(*args)
      end
    end

    def self.apply!
      return unless defined?(ActionView::Template::HTML)

      ActionView::Template::HTML.prepend(HtmlRenderAcceptsBlock)
    end
  end
end

EnvManager::ActionViewHtmlTemplateRenderPatch.apply!
