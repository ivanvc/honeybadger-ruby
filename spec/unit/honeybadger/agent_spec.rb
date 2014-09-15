require 'honeybadger/agent'

describe Honeybadger::Agent do
  describe 'class methods' do
    NULL_BLOCK = Proc.new{}.freeze

    subject { described_class }

    its(:callbacks) { should be_a Honeybadger::Config::Callbacks }
    its(:instance) { should be_nil }

    describe "::exception_filter" do
      it "configures the exception_filter callback" do
        expect { described_class.exception_filter(&NULL_BLOCK) }.to change(described_class.callbacks, :exception_filter).from(nil).to(NULL_BLOCK)
      end
    end

    describe "::exception_fingerprint" do
      it "configures the exception_fingerprint callback" do
        expect { described_class.exception_fingerprint(&NULL_BLOCK) }.to change(described_class.callbacks, :exception_fingerprint).from(nil).to(NULL_BLOCK)
      end
    end

    describe "::backtrace_filter" do
      it "configures the backtrace_filter callback" do
        expect { described_class.backtrace_filter(&NULL_BLOCK) }.to change(described_class.callbacks, :backtrace_filter).from(nil).to(NULL_BLOCK)
      end
    end

    describe "::start" do
      let(:config) { Honeybadger::Config.new(logger: NULL_LOGGER) }
      let(:logger) { double('Logger', level: 0, debug: nil, info: nil, warn: nil, error: nil) }

      subject { described_class.start(config) }

      before do
        allow(config).to receive(:logger) { logger }
        allow(config).to receive(:ping).and_return(true)

        # This is a quick win, but beware:
        # https://relishapp.com/rspec/rspec-mocks/docs/working-with-legacy-code/any-instance
        # Dependency injection (of Worker) may be a better option, eventually.
        allow_any_instance_of(Honeybadger::Worker).to receive(:start).and_return(true)
        allow_any_instance_of(Honeybadger::Worker).to receive(:stop).and_return(true)

        # Don't actually load plugins
        allow(Honeybadger::Plugin).to receive(:instances).and_return({})
      end

      after { described_class.stop }

      context "when config is a hash" do
        let(:hash) { {api_key: 'asdf', logger: NULL_LOGGER} }

        it "generates a new config" do
          allow(config).to receive(:valid?).and_return(true)
          allow(Honeybadger::Config).to receive(:new).with(hash).and_return(config)
          expect(described_class).to receive(:new).with(config).and_call_original
          described_class.start(hash)
        end
      end

      context "when disabled" do
        before { config[:disabled] = true }

        it { should eq false }

        it "logs failure to start" do
          expect(logger).to receive(:info).with(/disabled/)
          described_class.start(config)
        end

        it "doesn't create an instance" do
          expect { described_class.start(config) }.not_to change(Honeybadger::Agent, :instance)
        end
      end

      context "when config is invalid" do
        before { allow(config).to receive(:valid?) { false } }

        it { should eq false }

        it "logs failure to start" do
          expect(logger).to receive(:warn).with(/invalid/)
          described_class.start(config)
        end

        it "doesn't create an instance" do
          expect { described_class.start(config) }.not_to change(Honeybadger::Agent, :instance)
        end
      end

      context "when config is valid" do
        before { allow(config).to receive(:valid?) { true } }

        context "when ping fails" do
          before do
            allow(config).to receive(:ping).and_return(false)
          end

          it { should eq false }

          it "logs failure to start" do
            expect(logger).to receive(:warn).with(/failed to connect/)
            described_class.start(config)
          end

          it "doesn't create an instance" do
            expect { described_class.start(config) }.not_to change(Honeybadger::Agent, :instance)
          end
        end

        context "when ping succeeds" do
          it { should eq true }

          it "logs when started" do
            expect(logger).to receive(:info).with(/Starting Honeybadger/)
            described_class.start(config)
          end

          it "logs the version" do
            expect(logger).to receive(:info).with(/#{Regexp.escape(Honeybadger::VERSION)}/)
            described_class.start(config)
          end

          it "creates an instance" do
            instance = double('Honeybadger::Agent', start: true, stop: true)
            expect(described_class).to receive(:new).with(config).and_return(instance)
            expect { described_class.start(config) }.to change(Honeybadger::Agent, :instance).to(instance)
          end
        end
      end
    end
  end
end