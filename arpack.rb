class Arpack < Formula
  desc "ARPACK is a collection of Fortran77 subroutines designed to solve large scale eigenvalue problems."
  homepage "https://github.com/opencollab/arpack-ng"
  url "https://github.com/opencollab/arpack-ng/archive/3.2.0.tar.gz"
  sha256 "ce6de85d8de6ae3a741fb9d6169c194ff1b2ffdab289f7af8e41d71bb7818cbb"
  head "https://github.com/opencollab/arpack-ng.git"

  bottle do
    sha256 "6279a2b0072b0e362d50d218fde6b0ec6ce0dd841e7c143f0045ea0b60601f34" => :yosemite
    sha256 "13e906401589f1964d9847e6e291b03f55bf8de7b25968d6ca31124482a8ff6e" => :mavericks
    sha256 "a17839b8ec3e0599361674bc2211cff6705e04661cab093f80ea4edea2b757b0" => :mountain_lion
  end

  # TODO: enable with 3.3.0
  # option "without-check", "skip tests (not recommended)"

  depends_on :fortran
  depends_on :mpi => [:optional, :f77]
  depends_on "openblas" => :optional
  depends_on "veclibfort" if build.without?("openblas") && OS.mac?

  def install
    ENV.m64 if MacOS.prefer_64_bit?

    cc_args = (build.with? :mpi) ? ["F77=#{ENV["MPIF77"]}"] : []
    args = cc_args + ["--disable-dependency-tracking", "--prefix=#{libexec}"]
    args << "--enable-mpi" if build.with? :mpi
    if build.with? "openblas"
      args << "--with-blas=-L#{Formula["openblas"].opt_lib} -lopenblas"
    elsif OS.mac?
      args << "--with-blas=-L#{Formula["veclibfort"].opt_lib} -lvecLibFort"
    else
      args << "--with-blas=-lblas -llapack"
    end

    # HEAD version does not contain generated configure scirpt
    # must bootstrap first:
    system "./bootstrap" if build.head?

    system "./configure", *args
    system "make"
    system "make", "check" if build.with? "check"
    system "make", "install"
    lib.install_symlink Dir["#{libexec}/lib/*"].select { |f| File.file?(f) }
    (lib / "pkgconfig").install_symlink Dir["#{libexec}/lib/pkgconfig/*"]
    (libexec / "share").install "TESTS/testA.mtx"
  end

  test do
    if build.with? "mpi"
      cd libexec/"bin" do
        ["pcndrv1", "pdndrv1", "pdndrv3", "pdsdrv1", "psndrv3", "pssdrv1", "pzndrv1"].each do |slv|
          system "mpirun -np 4 #{slv}" if build.with? "mpi"
        end
      end
    end
  end
end
