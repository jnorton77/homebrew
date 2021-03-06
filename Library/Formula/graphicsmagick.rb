require 'formula'

class Graphicsmagick < Formula
  homepage 'http://www.graphicsmagick.org/'
  url 'http://downloads.sourceforge.net/project/graphicsmagick/graphicsmagick/1.3.19/GraphicsMagick-1.3.19.tar.bz2'
  sha256 'b57cdeb1ab9492b667776bbbc265149eda5601d2c572d65f43b44273e892fff1'
  head 'hg://http://graphicsmagick.hg.sourceforge.net:8000/hgroot/graphicsmagick/graphicsmagick'

  option 'with-quantum-depth-8', 'Compile with a quantum depth of 8 bit'
  option 'with-quantum-depth-16', 'Compile with a quantum depth of 16 bit'
  option 'with-quantum-depth-32', 'Compile with a quantum depth of 32 bit'
  option 'without-magick-plus-plus', 'disable build/install of Magick++'
  option 'without-svg', 'Compile without svg support'
  option 'with-perl', 'Build PerlMagick; provides the Graphics::Magick module'

  depends_on :libtool => :run

  depends_on 'pkg-config' => :build

  depends_on 'jpeg' => :recommended
  depends_on :libpng => :recommended
  depends_on :freetype => :recommended

  depends_on :x11 => :optional
  depends_on 'libtiff' => :optional
  depends_on 'little-cms' => :optional
  depends_on 'little-cms2' => :optional
  depends_on 'jasper' => :optional
  depends_on 'libwmf' => :optional
  depends_on 'ghostscript' => :optional

  opoo '--with-ghostscript is not recommended' if build.with? 'ghostscript'

  fails_with :llvm do
    build 2335
  end

  skip_clean :la

  def ghostscript_fonts?
    File.directory? "#{HOMEBREW_PREFIX}/share/ghostscript/fonts"
  end

  def install
    args = [ "--prefix=#{prefix}",
             "--disable-dependency-tracking",
             "--enable-shared",
             "--disable-static",
             "--with-modules",
             "--disable-openmp"]

    args << "--without-gslib" unless build.with? 'ghostscript'
    args << "--with-gs-font-dir=#{HOMEBREW_PREFIX}/share/ghostscript/fonts" unless build.with? 'ghostscript'
    args << "--without-magick-plus-plus" if build.without? 'magick-plus-plus'
    args << "--with-perl" if build.include? 'with-perl'

    if build.with? 'quantum-depth-32'
      quantum_depth = 32
    elsif build.with? 'quantum-depth-16'
      quantum_depth = 16
    elsif build.with? 'quantum-depth-8'
      quantum_depth = 8
    end

    args << "--with-quantum-depth=#{quantum_depth}" if quantum_depth
    args << "--without-x" unless build.with? 'x11'
    args << "--without-ttf" if build.without? 'freetype'
    args << "--without-xml" if build.without? 'svg'
    args << "--without-lcms" unless build.with? 'little-cms'
    args << "--without-lcms2" unless build.with? 'little-cms2'

    # versioned stuff in main tree is pointless for us
    inreplace 'configure', '${PACKAGE_NAME}-${PACKAGE_VERSION}', '${PACKAGE_NAME}'
    system "./configure", *args
    system "make", "install"
    if build.include? 'with-perl'
      cd 'PerlMagick' do
        # Install the module under the GraphicsMagick prefix
        system "perl", "Makefile.PL", "INSTALL_BASE=#{prefix}"
        system "make"
        system "make", "install"
      end
    end
  end

  test do
    system "#{bin}/gm", "identify", "/usr/share/doc/cups/images/cups.png"
  end

  def caveats
    if build.include? 'with-perl'
      <<-EOS.undent
        The Graphics::Magick perl module has been installed under:

          #{lib}

      EOS
    end
  end
end
