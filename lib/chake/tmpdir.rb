module Chake
  def self.tmpdir
    ENV.fetch('CHAKE_TMPDIR', 'tmp/chake')
  end
end
