Name:           food-invaders
Version:        %{release_version}
Release:        1%{?dist}
Summary:        16-bit NASM arcade game with colored ASCII art
License:        MIT AND GPL-2.0-only
URL:            https://github.com/Patt-00/Food-Invaders
BuildArch:      x86_64
Source0:        food-invaders-stage.tar.gz

%description
Food Invaders is a 16-bit Assembly arcade game for DOSBox-X. This package
bundles the game, a DOSBox-X runtime, and the corresponding DOSBox-X source.

%prep

%build

%install
mkdir -p %{buildroot}
tar -xzf %{SOURCE0} -C %{buildroot}

%check
test -x %{buildroot}/opt/food-invaders/runtime/bin/dosbox-x
test -x %{buildroot}/usr/bin/food-invaders
test -f %{buildroot}/opt/food-invaders/game/INVADERS.COM
test -f %{buildroot}/usr/share/doc/food-invaders/third-party/dosbox-x-source.tar.gz

%files
%license /usr/share/doc/food-invaders/LICENSE
%license /usr/share/doc/food-invaders/third-party/DOSBox-X-COPYING
%doc /usr/share/doc/food-invaders/README.md
%doc /usr/share/doc/food-invaders/THIRD-PARTY-NOTICES.md
%doc /usr/share/doc/food-invaders/third-party/DOSBox-X-SOURCE.txt
%doc /usr/share/doc/food-invaders/third-party/dosbox-x-source.tar.gz
/opt/food-invaders
/usr/bin/food-invaders
/usr/share/applications/food-invaders.desktop

%changelog
* Tue Nov 10 2026 Food Invaders contributors <318558214+Patt-00@users.noreply.github.com> - %{release_version}-1
- Package the game with DOSBox-X and its corresponding source.
