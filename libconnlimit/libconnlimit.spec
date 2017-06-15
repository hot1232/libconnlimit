Name: libconnlimit
Version: 0.1
Release: 1%{?dist}
Summary: nac conn limit module
Group: koudai
License: GNU
URL: http://www.com
Source0: libconnlimit.tar.gz
BuildRequires: hiredis
Requires: hiredis
%description
tenging lua connlimit

%prep
%setup -n %{name}

%build
gcc -c -fpic libconnlimit.c
gcc -shared libconnlimit.o -o libconnlimit.so -lhiredis
%install
rm -rf $RPM_BUILD_ROOT
if [ ! -d $RPM_BUILD_ROOT/lib64 ]
then
mkdir -p $RPM_BUILD_ROOT/lib64
fi


/usr/bin/install -m 755 libconnlimit.so $RPM_BUILD_ROOT/lib64/libconnlimit.so

%clean
rm -rf $RPM_BUILD_ROOT

%files
/lib64/libconnlimit.so

%defattr(-,root,root,-)

%attr(755,root,root) /lib64/libconnlimit.so
%doc
 
%changelog
