{ stdenv
, buildPythonPackage
, fetchPypi
, python
, zope_interface
, incremental
, automat
, constantly
, hyperlink
, pyhamcrest
, attrs
, pyopenssl
, service-identity
, setuptools
, idna
}:
buildPythonPackage rec {
  pname = "Twisted";
  version = "20.3.0";

  src = fetchPypi {
    inherit pname version;
    extension = "tar.bz2";
    sha256 = "040yzha6cyshnn6ljgk2birgh6mh2cnra48xp5ina5vfsnsmab6p";
  };

  propagatedBuildInputs = [ zope_interface incremental automat constantly hyperlink pyhamcrest attrs setuptools ];

  passthru.extras.tls = [ pyopenssl service-identity idna ];

  # Patch t.p._inotify to point to libc. Without this,
  # twisted.python.runtime.platform.supportsINotify() == False
  patchPhase = stdenv.lib.optionalString stdenv.isLinux ''
    substituteInPlace src/twisted/python/_inotify.py --replace \
      "ctypes.util.find_library('c')" "'${stdenv.glibc.out}/lib/libc.so.6'"
  '';

  # Generate Twisted's plug-in cache.  Twisted users must do it as well.  See
  # http://twistedmatrix.com/documents/current/core/howto/plugin.html#auto3
  # and http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=477103 for
  # details.
  postFixup = ''
    $out/bin/twistd --help > /dev/null
  '';

  checkPhase = ''
    ${python.interpreter} -m unittest discover -s twisted/test
  '';
  # Tests require network
  doCheck = false;

  meta = with stdenv.lib; {
    homepage = https://twistedmatrix.com/;
    description = "Twisted, an event-driven networking engine written in Python";
    longDescription = ''
      Twisted is an event-driven networking engine written in Python
      and licensed under the MIT license.
    '';
    license = licenses.mit;
    maintainers = [ ];
  };
}
