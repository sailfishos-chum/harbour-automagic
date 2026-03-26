Name:       harbour-automagic

# >> macros
# << macros
%define _binary_payload w2.xzdio
%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}

Summary:    Automagic Automation on Sailfish
Version:    1.0.13
Release:    1
License:    GPLv3
BuildArch:  noarch
URL:        https://qml.app/automagic/
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   libsailfishapp-launcher
Requires:    pyotherside-qml-plugin-python3-qt5 >= 1.2

#Requires:    python3-urllib3
#Requires:    python3-requests
#Requires:    python3-mutagen

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.3
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils

# not sure
BuildRequires:  qt5-qttools-linguist
#BuildRequires:  python3-devel
#BuildRequires:  python3-rpm-macros
#BuildRequires:  python3-setuptools


%description
Automate many things with a daemon 


%prep
%setup -q -n %{name}-%{version}

%build

%qmake5 

%make_build


%install
%qmake5_install


desktop-file-install --delete-original         --dir %{buildroot}%{_datadir}/applications                %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%defattr(0644,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
