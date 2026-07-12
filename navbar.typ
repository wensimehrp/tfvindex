#import html: *
#import "data.typ": htmls
// Checkbox for navigation panel
#input(
  type: "checkbox",
  id: "sidebar-toggle",
  class: "peer fixed top-0 left-0 translate-x-0 checked:translate-x-72 appearance-none"
    + " w-10 h-25 checked:w-full checked:h-full z-100 md:checked:w-10 md:checked:h-25",
)
// nasty inline JS for memoizing the toggle's state
#script(
  ```js
    const checkbox = document.querySelector('#sidebar-toggle');
    checkbox.checked = localStorage.getItem('sidebarOpen') !== 'false';
    checkbox.addEventListener('change', (e) => {
      localStorage.setItem('sidebarOpen', e.target.checked);
    });
  ```.text,
)
#div(
  class: "top-0 left-0 fixed z-200"
    + " -translate-x-72 peer-checked:translate-x-0 transition-transform"
    + " print:hidden",
  {
    // handle
    div(
      class: "absolute top-0 left-full"
        + " w-5 h-20"
        + " bg-stone-200 border-r border-b border-gray-500/30 dark:bg-zinc-700 dark:border-transparent"
        + " pointer-events-none",
      div(
        class: "w-full h-full",
        style: ```css
        background: linear-gradient(
          90deg,
          transparent 35%,
          #aaaa 35%, #aaaa 45%,
          transparent 45%, transparent 55%,
          #aaaa 55%, #aaaa 65%,
          transparent 65%
        );
        background-size: 100% 32px;
        background-position: center;
        background-repeat: no-repeat;
        ```.text,
      ),
    )
    nav(
      class: "w-72 grid grid-rows-[min-content_1fr] h-screen"
        + " bg-stone-200 border-r border-gray-500/30 dark:bg-zinc-700 dark:border-transparent"
        + " prose dark:prose-invert"
        + " shadow-sm md:shadow-none",
      {
        div(
          class: "flex bg-stone-100 dark:bg-zinc-300",
          div(
            class: (
              "flex items-center justify-center w-10 h-10 no-underline"
                + " border-r border-gray-500/30 hover:bg-stone-200"
                + " dark:bg-zinc-400 dark:border-transparent dark:hover:bg-zinc-500"
            )
              .split(" ")
              .map(it => "*:" + it)
              .join(" "),

            std.link(<home>, image("home.svg")),
          )
            + elem("pagefind-modal-trigger", attrs: (class: "w-full h-full"))
            + elem("pagefind-modal"),
        )
        div(
          id: "sidebar-scroll",
          class: "flex flex-wrap gap-2 overflow-y-auto p-4 border-t border-gray-500/30 dark:border-transparent "
            + (
              "bg-transparent dark:bg-zinc-600"
                + " border border-gray-500/30 dark:border-transparent"
                + " flex-auto text-center px-2 py-0.5 no-underline hover:ring"
            )
              .split(" ")
              .map(it => "*:" + it)
              .join(" "),
          {
            for label in htmls {
              std.link(label, str(label))
            }
          },
        )
      },
    )
  },
)
#script(
  ```js
    document.addEventListener('DOMContentLoaded', () => {
      const sidebar = document.querySelector('#sidebar-scroll');
      const savedScroll = sessionStorage.getItem('sidebar-scroll-position');
      if (sidebar && savedScroll) {
        sidebar.scrollTop = parseInt(savedScroll, 10);
      }
    });
    window.addEventListener('beforeunload', () => {
      const sidebar = document.querySelector('#sidebar-scroll');
      if (sidebar) {
        sessionStorage.setItem('sidebar-scroll-position', sidebar.scrollTop);
      }
    });
  ```.text,
)
