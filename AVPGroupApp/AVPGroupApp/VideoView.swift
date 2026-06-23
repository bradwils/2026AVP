import SwiftUI
import WebKit

// MARK: - WKWebView wrapper to embed YouTube iframe

struct YouTubePlayerView: UIViewRepresentable {

    let videoID: String
    var onVideoEnd: (() -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(onVideoEnd: onVideoEnd) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Allow JS message to notify when video ends
        let controller = config.userContentController
        controller.add(context.coordinator, name: "videoEnded")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        context.coordinator.webView = webView
        webView.loadHTMLString(htmlString(videoID: videoID), baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func htmlString(videoID: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          * { margin:0; padding:0; box-sizing:border-box; }
          body { background: black; display:flex; align-items:center; justify-content:center; height:100vh; }
          iframe { width:100vw; height:100vh; border:none; }
        </style>
        </head>
        <body>
          <div id="player"></div>
          <script>
            var tag = document.createElement('script');
            tag.src = "https://www.youtube.com/iframe_api";
            var firstScriptTag = document.getElementsByTagName('script')[0];
            firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

            var player;
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                height: '100%',
                width: '100%',
                videoId: '\(videoID)',
                playerVars: {
                  autoplay: 1,
                  playsinline: 1,
                  rel: 0,
                  modestbranding: 1
                },
                events: {
                  onStateChange: function(event) {
                    if (event.data === YT.PlayerState.ENDED) {
                      window.webkit.messageHandlers.videoEnded.postMessage('ended');
                    }
                  }
                }
              });
            }
          </script>
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        var onVideoEnd: (() -> Void)?
        weak var webView: WKWebView?

        init(onVideoEnd: (() -> Void)?) { self.onVideoEnd = onVideoEnd }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            if message.name == "videoEnded" {
                DispatchQueue.main.async { self.onVideoEnd?() }
            }
        }
    }
}

// MARK: - Video phase view

struct VideoView: View {

    @Environment(AppModel.self) private var appModel
    @State private var showReplayOption = false

    // Extracted YouTube video ID from: https://youtu.be/Plse2FOkV4Q
    private let videoID = "Plse2FOkV4Q"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showReplayOption {
                // Post-video options screen
                postVideoOptions
            } else {
                // Video player
                YouTubePlayerView(videoID: videoID) {
                    withAnimation { showReplayOption = true }
                    appModel.videoDidFinish = true
                }
                .ignoresSafeArea()

                // Skip button (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            appModel.skipVideo()
                        } label: {
                            Label("Skip Video", systemImage: "forward.end.fill")
                                .font(.callout)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.7))
                        .padding(30)
                    }
                }
            }
        }
    }

    private var postVideoOptions: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.07, blue: 0.18),
                         Color(red: 0.08, green: 0.12, blue: 0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 36) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("Video Complete")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Ready to practise CPR?")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 24) {
                    Button {
                        showReplayOption = false
                        appModel.replayVideo()
                    } label: {
                        Label("Replay Video", systemImage: "arrow.counterclockwise")
                            .font(.title3)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.6))

                    Button {
                        appModel.videoFinished()
                    } label: {
                        Label("Start Practice", systemImage: "arrow.right.circle.fill")
                            .font(.title3.bold())
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding(60)
        }
    }
}
