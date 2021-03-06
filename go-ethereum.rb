require 'formula'

class GoEthereum < Formula

  # official_version-protocol_version
  version '0.7.11-49'

  homepage 'https://github.com/ethereum/go-ethereum'
  url 'https://github.com/ethereum/go-ethereum.git', :branch => 'master'

  devel do
    version '0.8.2-52'
    url 'https://github.com/ethereum/go-ethereum.git', :branch => 'develop'
  end

  depends_on 'go' => :build
  depends_on 'hg' => :build
  depends_on 'pkg-config' => :build
  depends_on 'qt5'
  depends_on 'gmp'

  option "headless", "Headless"

  def install
    ENV["PKG_CONFIG_PATH"] = "#{HOMEBREW_PREFIX}/opt/qt5/lib/pkgconfig"
    ENV["QT5VERSION"] = `pkg-config --modversion Qt5Core`
    ENV["CGO_CPPFLAGS"] = "-I#{HOMEBREW_PREFIX}/opt/qt5/include/QtCore"
    ENV["GOPATH"] = "#{buildpath}"
    ENV["GOROOT"] = "#{HOMEBREW_PREFIX}/opt/go/libexec"

    # Debug env
    system "go", "env"
    base = "src/github.com/ethereum/go-ethereum"

    mkdir_p base
    Dir["**"].reject{ |f| f['src']}.each do |filename|
      move filename, "#{base}/"
    end

    # fix develop vs master discrepancies
    cmd = "#{base}/cmd/"
    # unless build.devel?
    #   cmd = "#{base}/"
    # end

    # Get dependencies
    system "go", "get", "-v", "-t", "-d", "./#{cmd}ethereum"
    system "go", "get", "-v", "-t", "-d", "./#{cmd}mist" unless build.include? "headless"

    system "go", "build", "-v", "./#{cmd}ethereum"
    system "go", "build", "-v", "./#{cmd}mist" unless build.include? "headless"

    bin.install 'ethereum'
    bin.install 'mist' unless build.include? "headless"

    move "#{cmd}mist/assets", prefix/"Resources"

    prefix.install Dir['src']
  end

  test do
    system "ethereum"
    system "mist" unless build.include? "headless"
  end

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>ThrottleInterval</key>
        <integer>300</integer>
        <key>ProgramArguments</key>
        <array>
            <string>#{opt_bin}/ethereum</string>
            <string>-datadir=#{prefix}/.ethereum</string>
            <string>-id=buildslave</string>
        </array>
        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}</string>
      </dict>
    </plist>
    EOS
  end
end
__END__
