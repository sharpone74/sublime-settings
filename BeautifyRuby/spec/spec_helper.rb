unless ENV['CI'] == true
  require 'pry'
end

require 'yaml'
require_relative './../lib/rbeautify.rb'

module RBeautifyMatchers
  # Adds more descriptive failure messages to the dynamic be_valid matcher
  class BeBlockStartLike #:nodoc:
    def initialize(block_matcher_name, offset, match, after_match)
      # triggers the standard Spec::Matchers::Be magic, as if the original Spec::Matchers#method_missing had fired
      @block_matcher_name = block_matcher_name
      @offset             = offset
      @match              = match
      @after_match        = after_match
    end

    def matches?(target_block)
      @target_block = target_block
      return !target_block.nil? &&
        (expected_string == got_string)
    end

    def failure_message
      "expected\n#{expected_string} but got\n#{got_string}"
    end

    def failure_message_when_negated
      "expected to be different from #{expected_string}"
    end

    def expected_string
      "name: #{@block_matcher_name}, offset: #{@offset}, match: '#{@match}', after_match: '#{@after_match}'"
    end

    def got_string
      "name: #{@target_block.block_matcher.name}, offset: #{@target_block.offset}, match: '#{@target_block.match}', after_match: '#{@target_block.after_match}'"
    end

    def description
      "block start with"
    end
  end

  class BeBlockEndLike #:nodoc:
    def initialize(block_start, offset, match, after_match)
      # triggers the standard Spec::Matchers::Be magic, as if the original Spec::Matchers#method_missing had fired
      @block_start = block_start
      @offset = offset
      @match = match
      @after_match = after_match
    end

    def matches?(target_block)
      @target_block = target_block
      expected_string == got_string
    end

    def failure_message
      "expected\n#{expected_string} but got\n#{got_string}"
    end

    def failure_message_when_negated
      "expected to be different from #{expected_string}"
    end

    def expected_string
      "block_end: #{@block_start.name}, offset: #{@offset}, match: '#{@match}', after_match: '#{@after_match}'"
    end

    def got_string
      if @target_block.nil?
        'nil'
      else
        "block_end: #{@target_block.block_start.name}, offset: #{@target_block.offset}, match: '#{@target_block.match}', after_match: '#{@target_block.after_match}'"
      end
    end

    def description
      "block end with"
    end

  end

  def be_block_start_like(block_matcher, offset, match, after_match)
    BeBlockStartLike.new(block_matcher, offset, match, after_match)
  end

  def be_block_end_like(block_start, offset, match, after_match)
    BeBlockEndLike.new(block_start, offset, match, after_match)
  end
end

RSpec.configure do |config|
  config.include(RBeautifyMatchers)
end

def run_fixtures_for_language(language)
  fixtures = YAML.load_file(File.dirname(__FILE__) + "/fixtures/#{language}.yml")

  describe language do
    let(:config) do
      {
        'tab_size' => 2,
        'translate_tabs_to_spaces' => 'true'
      }
    end

    fixtures.each do |fixture|
      it "should #{fixture['name']}" do
        input  = fixture['input']
        output = fixture['output'] || input
        debug  = fixture['debug'] || false

        config['tab_size'] = fixture.fetch('spaces', 2)

        if fixture['pending']
          next
          pending fixture['pending'] do
            expect(RBeautify.beautify_string(language, input, config)).to eq(output)
          end
        else
          RBeautify::BlockMatcher.debug = debug
          expect(RBeautify.beautify_string(language, input, config)).to eq(output)
        end
      end
    end
  end

end
