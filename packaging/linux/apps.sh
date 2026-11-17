# What each application ships on Linux and what it needs, per family.
#
# Sourced by inside.sh with APP set. Paths in the stage_* functions are relative to the
# application's source tree (/src/<app>) and the stage root ($STAGE, laid out as /usr).
#
# Dependencies: the .deb's library dependencies come from dpkg-shlibdeps and the .rpm's
# from rpmbuild's own soname scan, so the lists below are only what a soname cannot say:
# programs run as processes, GStreamer plugins, and what each family calls optional.
# Arch has no such scan, so its `depends` names the libraries too.

case "$APP" in
sulekha)
    NAME=Sulekha
    SUMMARY="PDF viewer and stylus annotator"
    DESCRIPTION="Read, annotate and present PDFs: pressure-sensitive ink saved into the PDF, a presenter view with speaker notes, talks recorded and exported to video, and two revisions compared word by word."
    URL=https://www.andolika.com/sulekha/
    BINARIES=(sulekha)
    ARCH_DEPENDS=(gtk4 libadwaita alsa-lib cairo pango graphene glib2 gcc-libs glibc)
    ARCH_OPTDEPENDS=('ffmpeg: export a recorded talk to video'
                     'gst-plugins-good: play video embedded in a PDF'
                     'gst-libav: decode H.264 video embedded in a PDF')
    DEB_DEPENDS=()
    DEB_RECOMMENDS=(gstreamer1.0-plugins-good gstreamer1.0-libav)
    DEB_SUGGESTS=(ffmpeg)
    RPM_REQUIRES=()
    RPM_RECOMMENDS=(gstreamer1-plugins-good gstreamer1-plugin-libav)
    RPM_SUGGESTS=(ffmpeg-free)
    stage() {
        install -Dm755 "$TARGET/release/sulekha" "$STAGE/usr/bin/sulekha"
        # One binary carries both engines; these names only choose (see the Makefile).
        for e in hayro mupdf; do
            printf '#!/bin/sh\nexec env SULEKHA_PDF_ENGINE=%s /usr/bin/sulekha "$@"\n' "$e" > "$STAGE/usr/bin/sulekha-$e"
            chmod 755 "$STAGE/usr/bin/sulekha-$e"
        done
        install -Dm644 data/org.andolika.Sulekha.desktop "$STAGE/usr/share/applications/org.andolika.Sulekha.desktop"
        install -Dm644 data/org.andolika.Sulekha.metainfo.xml "$STAGE/usr/share/metainfo/org.andolika.Sulekha.metainfo.xml"
        install -Dm644 data/icons/hicolor/scalable/apps/org.andolika.Sulekha.svg "$STAGE/usr/share/icons/hicolor/scalable/apps/org.andolika.Sulekha.svg"
        install -Dm644 data/sulekha.1 "$STAGE/usr/share/man/man1/sulekha.1"
    }
    ;;
lipi)
    NAME=Lipi
    SUMMARY="LaTeX editor, collaborative without a server"
    DESCRIPTION="Write LaTeX with the PDF beside the source, rebuilt as you pause; errors explained, references checked against the published record, and several people writing one project at once, peer to peer. The files on disk stay plain .tex."
    URL=https://www.andolika.com/lipi/
    BINARIES=(lipi)
    ARCH_DEPENDS=(gtk4 libadwaita gtksourceview5 libspelling cairo pango graphene glib2 gcc-libs glibc)
    ARCH_OPTDEPENDS=('texlive-basic: build documents'
                     'texlive-latexextra: the packages most documents use'
                     'texlab: completion, go to definition and ChkTeX'
                     'hunspell-en_us: spell checking in English'
                     'git: version control and merging through git'
                     'gst-plugins-good: play video embedded in a preview')
    DEB_DEPENDS=()
    DEB_RECOMMENDS=(texlive-latex-recommended latexmk hunspell-en-us git)
    DEB_SUGGESTS=(texlive-latex-extra gstreamer1.0-plugins-good)
    RPM_REQUIRES=()
    RPM_RECOMMENDS=(texlive-scheme-basic latexmk hunspell-en-US git)
    RPM_SUGGESTS=(texlive-collection-latexextra gstreamer1-plugins-good)
    stage() {
        install -Dm755 "$TARGET/release/lipi" "$STAGE/usr/bin/lipi"
        install -Dm644 data/org.andolika.Lipi.desktop "$STAGE/usr/share/applications/org.andolika.Lipi.desktop"
        install -Dm644 data/icons/org.andolika.Lipi.svg "$STAGE/usr/share/icons/hicolor/scalable/apps/org.andolika.Lipi.svg"
    }
    ;;
dekho)
    NAME=dekho
    SUMMARY="File manager with tabs, split panes and previews"
    DESCRIPTION="A file manager with tabs, split panes, previews for images, PDFs, video, Markdown and source, git status on every file, find in files and a command palette."
    URL=https://www.andolika.com/
    BINARIES=(dekho)
    ARCH_DEPENDS=(gtk4 libadwaita gtksourceview5 poppler-glib libheif gstreamer gst-plugins-base-libs gst-plugin-gtk4 cairo pango graphene glib2 gcc-libs glibc)
    ARCH_OPTDEPENDS=('ripgrep: find in files'
                     'fd: the command palette and search in folder'
                     'git: status badges and the Git menu'
                     'ffmpegthumbnailer: video thumbnails'
                     'unzip: zip archives'
                     '7zip: 7z archives'
                     'gst-plugins-good: play audio and video'
                     'gst-libav: decode most video')
    DEB_DEPENDS=(gstreamer1.0-gtk4)
    DEB_RECOMMENDS=(ripgrep fd-find git unzip gstreamer1.0-plugins-good)
    DEB_SUGGESTS=(ffmpegthumbnailer 7zip gstreamer1.0-libav)
    RPM_REQUIRES=(gstreamer1-plugin-gtk4)
    RPM_RECOMMENDS=(ripgrep fd-find git unzip gstreamer1-plugins-good)
    RPM_SUGGESTS=(ffmpegthumbnailer p7zip gstreamer1-plugin-libav)
    stage() {
        install -Dm755 "$TARGET/release/dekho" "$STAGE/usr/bin/dekho"
        install -Dm644 data/org.octree.dekho.desktop "$STAGE/usr/share/applications/org.octree.dekho.desktop"
    }
    ;;
dakia)
    NAME=Dakia
    SUMMARY="Email client over notmuch and isync"
    DESCRIPTION="Email over a local maildir, synced with isync and searched with notmuch: threads, search tabs, an Outbox with send-later, snooze, rules, contacts, todos and a calendar synced with Google."
    URL=https://www.andolika.com/
    BINARIES=(dakia)
    ARCH_DEPENDS=(gtk4 libadwaita webkitgtk-6.0 gtksourceview5 libspelling notmuch isync cairo pango graphene glib2 gcc-libs glibc)
    ARCH_OPTDEPENDS=('poppler: summarise a PDF attachment (pdftotext)'
                     'sulekha: sign a PDF attachment and return it')
    DEB_DEPENDS=(notmuch isync)
    DEB_RECOMMENDS=(poppler-utils)
    DEB_SUGGESTS=(sulekha)
    RPM_REQUIRES=(notmuch isync)
    RPM_RECOMMENDS=(poppler-utils)
    RPM_SUGGESTS=(sulekha)
    stage() {
        install -Dm755 "$TARGET/release/dakia" "$STAGE/usr/bin/dakia"
        install -Dm644 data/org.andolika.Dakia.desktop "$STAGE/usr/share/applications/org.andolika.Dakia.desktop"
        install -Dm644 data/org.andolika.Dakia.metainfo.xml "$STAGE/usr/share/metainfo/org.andolika.Dakia.metainfo.xml"
        install -Dm644 data/icons/hicolor/scalable/apps/org.andolika.Dakia.svg "$STAGE/usr/share/icons/hicolor/scalable/apps/org.andolika.Dakia.svg"
        for s in 16 22 24 32 48 64 128; do
            install -Dm644 "data/icons/hicolor/${s}x${s}/apps/org.andolika.Dakia.png" "$STAGE/usr/share/icons/hicolor/${s}x${s}/apps/org.andolika.Dakia.png"
        done
    }
    ;;
*)
    echo "unknown application: $APP" >&2
    exit 2
    ;;
esac
