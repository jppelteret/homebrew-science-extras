require "formula"

class NoExpatFramework < Requirement
  def expat_framework
    "/Library/Frameworks/expat.framework"
  end

  satisfy :build_env => false do
    not File.exist? expat_framework
  end

  def message; <<-EOS.undent
    Detected #{expat_framework}

    This will be picked up by CMake's build system and likely cause the
    build to fail, trying to link to a 32-bit version of expat.

    You may need to move this file out of the way to compile CMake.
    EOS
  end
end

class Cmake < Formula
  homepage "http://www.cmake.org/"
  url "http://www.cmake.org/files/v3.0/cmake-3.0.2.tar.gz"
  sha1 "379472e3578902a1d6f8b68a9987773151d6f21a"

  head do
    url "http://cmake.org/cmake.git"

    depends_on "xz" # For LZMA
  end

  option "without-docs", "Don't build man pages"
  depends_on :python => :build if MacOS.version <= :snow_leopard && build.with?("docs")

  depends_on "qt" => :optional

  resource "sphinx" do
    url "https://pypi.python.org/packages/source/S/Sphinx/Sphinx-1.2.3.tar.gz"
    sha1 "3a11f130c63b057532ca37fe49c8967d0cbae1d5"
  end

  resource "docutils" do
    url "https://pypi.python.org/packages/source/d/docutils/docutils-0.12.tar.gz"
    sha1 "002450621b33c5690060345b0aac25bc2426d675"
  end

  resource "pygments" do
    url "https://pypi.python.org/packages/source/P/Pygments/Pygments-1.6.tar.gz"
    sha1 "53d831b83b1e4d4f16fec604057e70519f9f02fb"
  end

  resource "jinja2" do
    url "https://pypi.python.org/packages/source/J/Jinja2/Jinja2-2.7.3.tar.gz"
    sha1 "25ab3881f0c1adfcf79053b58de829c5ae65d3ac"
  end

  resource "markupsafe" do
    url "https://pypi.python.org/packages/source/M/MarkupSafe/MarkupSafe-0.23.tar.gz"
    sha1 "cd5c22acf6dd69046d6cb6a3920d84ea66bdf62a"
  end

  depends_on NoExpatFramework

  def install
    if build.with? "docs"
      ENV.prepend_create_path "PYTHONPATH", buildpath+"sphinx/lib/python2.7/site-packages"
      resources.each do |r|
        r.stage do
          system "python", *Language::Python.setup_install_args(buildpath/"sphinx")
        end
      end

      # There is an existing issue around OS X & Python locale setting
      # See http://bugs.python.org/issue18378#msg215215 for explanation
      ENV["LC_ALL"] = "en_US.UTF-8"
    end

    args = %W[
      --prefix=#{prefix}
      --system-libs
      --no-system-libarchive
      --datadir=/share/cmake
      --docdir=/share/doc/cmake
      --mandir=/share/man
    ]

    if build.with? "docs"
      args << "--sphinx-man" << "--sphinx-build=#{buildpath}/sphinx/bin/sphinx-build"
    end

    args << "--qt-gui" if build.with? "qt"

    system "./bootstrap", *args
    system "make"
    system "make", "install"
    bin.install_symlink Dir["#{prefix}/CMake.app/Contents/bin/*"] if build.with? "qt"
  end

  test do
    (testpath/"CMakeLists.txt").write("find_package(Ruby)")
    system "#{bin}/cmake", "."
  end
end