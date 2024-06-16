// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

const hooks = {
  ModalCloser: {
    mounted() {
      this.handleEvent("close_modal", () => {
          console.log("Pushing close modal");
        this.el.dispatchEvent(new Event("click", { bubbles: true }));
      });
    },
  },
  RelayHook: {
    mounted() {
      relay = this;
      document.addEventListener("relay-event", (e) =>
        {
          console.log("Pushing");
          console.log(e.detail.event);
          relay.pushEvent(e.detail.event, e.detail.payload);
        }
      );
    },
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

window.addEventListener("app:requestSubmit", (event) => {
  const form = event.target;
  form.requestSubmit();
});

window.addEventListener("phx:exec-js", ({detail}) => {
    console.log("Received another JS event.");
    console.log(detail);
    liveSocket.execJS(document.getElementById(detail.to), detail.encodedJS)
});

window.dispatchToLV = function (event, payload) {
  let relay_event = new CustomEvent("relay-event", {
    detail: { event: event, payload: payload },
  });
  document.dispatchEvent(relay_event);
};
