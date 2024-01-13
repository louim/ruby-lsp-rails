# typed: strict
# frozen_string_literal: true

module RubyLsp
  module Rails
    class DocumentSymbol
      extend T::Sig
      extend T::Generic
      include Requests::Support::Common

      sig do
        params(
          stack: RubyDocument::DocumentSymbolStack,
          dispatcher: Prism::Dispatcher,
        ).void
      end
      def initialize(stack, dispatcher)
        @_response = T.let(nil, NilClass)
        @stack = stack

        dispatcher.register(self, :on_call_node_enter)
      end

      sig { params(node: Prism::CallNode).void }
      def on_call_node_enter(node)
        message_value = node.message
        return unless message_value == "test"

        return unless node.arguments

        arguments = node.arguments&.arguments
        return unless arguments&.any?

        first_argument = arguments.first

        content = case first_argument
        when Prism::InterpolatedStringNode
          parts = first_argument.parts

          if parts.all? { |part| part.is_a?(Prism::StringNode) }
            T.cast(parts, T::Array[Prism::StringNode]).map(&:content).join
          end
        when Prism::StringNode
          first_argument.content
        end

        return unless content && !content.empty?

        @stack.peek.children << RubyLsp::Interface::DocumentSymbol.new(
          name: content,
          kind: LanguageServer::Protocol::Constant::SymbolKind::METHOD,
          selection_range: range_from_node(node),
          range: range_from_node(node),
        )
      end
    end
  end
end
