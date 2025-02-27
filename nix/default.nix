{ lib, python310Packages, fetchFromGitHub, callPackage, pkgs, version ? "git"}:

python310Packages.buildPythonPackage rec {
  pname = "auto-cpufreq";
  inherit version;

  # src = fetchFromGitHub {
  #   owner = "AdnanHodzic";
  #   repo = pname;
  #   rev = "v${version}";
  #   sha256 = "sha256-ElYzVteBnoz7BevA6j/730BMG0RsmhBQ4PNl9+0Kw4k=";
  # };
  src = ../.;

  nativeBuildInputs = with pkgs; [ wrapGAppsHook gobject-introspection ];

  buildInputs = with pkgs; [ gtk3 ];

  propagatedBuildInputs = with python310Packages; [ requests pygobject3 click distro psutil setuptools (callPackage ./pkgs/setuptools-git-versioning.nix {})];

  doCheck = false;
  pythonImportsCheck = [ "auto_cpufreq" ];

  patches = [

    #  patch to prevent script copying and to disable install
    ./patches/prevent-install-and-copy.patch

  ];

  postPatch = ''
    substituteInPlace auto_cpufreq/core.py --replace '/opt/auto-cpufreq/override.pickle' /var/run/override.pickle
    substituteInPlace scripts/org.auto-cpufreq.pkexec.policy --replace "/opt/auto-cpufreq/venv/bin/auto-cpufreq" $out/bin/auto-cpufreq
  '';

  postInstall = ''
    # copy script manually
    cp scripts/cpufreqctl.sh $out/bin/cpufreqctl.auto-cpufreq

    # systemd service
    mkdir -p $out/lib/systemd/system
    cp scripts/auto-cpufreq.service $out/lib/systemd/system
    substituteInPlace $out/lib/systemd/system/auto-cpufreq.service --replace "/usr/local" $out

    # desktop icon
    mkdir -p $out/share/applications
    mkdir $out/share/pixmaps
    cp scripts/auto-cpufreq-gtk.desktop $out/share/applications
    cp images/icon.png $out/share/pixmaps/auto-cpufreq.png

    # polkit policy
    mkdir -p $out/share/polkit-1/actions
    cp scripts/org.auto-cpufreq.pkexec.policy $out/share/polkit-1/actions
  '';

  meta = with lib; {
    homepage = "https://github.com/AdnanHodzic/auto-cpufreq";
    description = "Automatic CPU speed & power optimizer for Linux";
    license = licenses.lgpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.Technical27 ];
    mainProgram = "auto-cpufreq";
  };
}
