# Labelled shells, and one keystroke to get between them.
#
# Labels come for free: Claude Code writes its current task into the terminal
# title, so the tab bar reads it rather than asking you to type anything. A
# label typed by hand (ctrl+a ,) is stored on the node and wins over the title.
# Either way the name lives on the server, so it survives detach/reattach.

(def- prefix "ctrl+a")

(defn- shells [] (group/mkdir :root "/shells"))

(defn- shell-panes [] (group/leaves (shells)))

(defn- sanitize [name]
  # tree/set-name drops whitespace and slashes outright, so fold them to dashes
  # rather than let it glue the words together.
  (->> name
       (string/replace-all "/" "-")
       (string/replace-all " " "-")))

(defn- title-of [id]
  (def [ok title] (protect (cmd/title id)))
  (if (and ok (string? title)) title ""))

(defn- rune-starts [s]
  # Titles open with Claude's status glyph, so budgets have to count runes
  # rather than bytes or the label loses three characters to one symbol.
  (filter |(not= 0x80 (band (get s $) 0xC0)) (range (length s))))

(defn- clip [s n]
  (def starts (rune-starts s))
  (if (<= (length starts) n) (break s))
  (def head (string/slice s 0 (get starts (- n 1))))
  (def space (last (string/find-all " " head)))
  # A whole word reads better than a truncated one, but not at any price.
  (if (and space (> space (/ n 2)))
    (string/slice head 0 space)
    (string head "…")))

# --- carryover ---------------------------------------------------------------
#
# A bar above the tabs counts what is still open in the standup carryover file
# and names as many items as the width allows. Lines are matched the way
# standup/bin/collect-sessions.sh matches them, so the bar and the morning
# notes can never disagree about what is outstanding.

(def- carryover-file (string (os/getenv "HOME" "") "/Dev/hbo/standup/carryover.md"))

# A fragment that stops on one of these reads as a truncation rather than an
# ending, so it drops the word instead of keeping it.
(def- dangling
  {"a" true "an" true "and" true "at" true "by" true "for" true "from" true
   "in" true "into" true "of" true "on" true "or" true "that" true "the" true
   "to" true "which" true "with" true})

(var- carryover-stamp nil)
(var- carryover-items @[])

(defn- rune-len [s] (length (rune-starts s)))

(defn- headline [s n]
  (def piece (clip s n))
  (def words (string/split " " piece))
  (def tail (string/ascii-lower (string/trim (last words) ",.;:-")))
  (if (and (> (length words) 1) (get dangling tail))
    (string/join (slice words 0 -2) " ")
    piece))

(defn- wrap [s width]
  # Breaking only on spaces keeps the multibyte characters in these items
  # whole; a byte-width cut would split one.
  (def lines @[])
  (var line @"")
  (each word (string/split " " s)
    (cond
      (empty? line) (buffer/push-string line word)
      (<= (+ (rune-len (string line)) 1 (rune-len word)) width)
      (do (buffer/push-string line " ")
          (buffer/push-string line word))
      (do (array/push lines (string line))
          (set line (buffer word)))))
  (array/push lines (string line))
  lines)

(defn- preview-text [s]
  # The preview window is a fixed 80x26, so a long item stops at the bottom
  # and says how much it is holding back rather than ending mid-sentence.
  (def lines (wrap s 76))
  (when (<= (length lines) 26) (break (string/join lines "\n")))
  (def shown (array/slice lines 0 25))
  # Plain: nothing in cy styles a :text preview, so escapes here may not render.
  (array/push shown (string "… " (- (length lines) 25) " more lines"))
  (string/join shown "\n"))

(defn- carryover-open []
  # :text runs on every render, so the file is re-read only once it moves.
  (def [ok stat] (protect (os/stat carryover-file)))
  (unless (and ok stat) (break @[]))
  (def stamp [(get stat :modified) (get stat :size)])
  (when (= stamp carryover-stamp) (break carryover-items))
  (set carryover-stamp stamp)
  (def [read? body] (protect (slurp carryover-file)))
  (set carryover-items
       (if read?
         (seq [[i line] :pairs (string/split "\n" body)
               :let [trimmed (string/triml line)]
               :when (string/has-prefix? "- [ ] " trimmed)]
           {:line (+ i 1)
            :text (->> (string/slice trimmed 6)
                       (string/replace-all "`" "")
                       (string/replace-all "**" "")
                       (string/trim))})
         @[]))
  carryover-items)

(defn- carryover-bar [[rows cols] node]
  (def items (carryover-open))
  (when (empty? items)
    (break (style/text " nothing carrying over" :fg "8" :italic true)))
  (def head (string " " (length items) " open"))
  (def out @[(style/text head :fg "3" :bold true)])
  # Whatever the count leaves goes to item text, first come. Under about
  # fourteen columns a fragment is more ellipsis than word, so the bar stops
  # naming items rather than trailing off into stubs.
  (var left (- cols (rune-len head)))
  (each item items
    (when (< left 17) (break))
    (def piece (headline (get item :text) (min 44 (- left 3))))
    (array/push out (style/text " · " :fg "8"))
    (array/push out (style/text piece :fg "8"))
    (set left (- left 3 (rune-len piece))))
  (string/join out))

(defn- add-carryover [node]
  # No bar at all on a machine without the file -- a blank row is worse than
  # the row going back to the tabs.
  (def [ok stat] (protect (os/stat carryover-file)))
  (if (and ok stat) (layout/bar carryover-bar node) node))

(defn- glyph-of [id]
  # Claude opens its title with a status rune: idle, or a spinner while it works.
  (def title (title-of id))
  (def starts (rune-starts title))
  (if (< (length starts) 2) "·" (string/slice title 0 (get starts 1))))

(defn- label-of [id width]
  (def pinned (param/get :shell-label :target id))
  (def title (title-of id))
  (clip (cond
          pinned pinned
          (not (empty? title)) title
          (tree/name id))
        width))

(defn- draw-tabs [active]
  (def panes (shell-panes))
  (when (empty? panes) (break))
  (def old (layout/get))
  (def margins? (layout/type? :margins old))
  (def cols (if margins? (get old :cols 80) 80))
  (def n (length panes))
  # Each tab spends four columns on its number and padding. The tab you are in
  # takes a fixed, generous share; the rest divide what is left. Below about
  # twelve columns a label is mostly ellipsis, so those tabs show their status rune
  # alone -- a quiet row of dots reads better than six truncated words.
  (def overhead (* n 4))
  (def here-width (min 34 (max 12 (- cols overhead 4))))
  (def unit (if (> n 1)
             (math/floor (/ (- cols overhead here-width) (- n 1)))
             0))
  (def tabs
    (layout/tabs
      (seq [[i id] :pairs panes]
        (def here (= id active))
        (def pinned (param/get :shell-label :target id))
        (def text (cond
                    here (label-of id here-width)
                    pinned (string (glyph-of id) " " (clip pinned (max 6 unit)))
                    (>= unit 12) (label-of id unit)
                    (glyph-of id)))
        # The colours go in the name rather than in :active-fg and friends,
        # which cy applies only when `len(name) == lipgloss.Width(name)`
        # (pkg/layout/tabs.go). That test is meant to spot a name that styles
        # itself, but it reads any multibyte character as an escape sequence,
        # so every tab carrying Claude's status rune came out unstyled and only
        # the plain shells highlighted. Still true in v1.12.1. ANSI indices
        # rather than hex, so the bar follows the terminal theme instead of
        # fighting it: the tab you are in is a filled block, the rest recede
        # into the background.
        (layout/tab
          (style/text (string " " (+ i 1) " " text " ")
                      :fg (if here "15" "8")
                      :bg (if here "4" nil))
          (layout/pane :id id :attached here)
          :active here))))
  (def top (add-carryover tabs))
  (layout/set (if margins? (assoc old :node top) top)))

(defn- switch-to [id]
  (pane/attach id)
  (draw-tabs id))

(defn- goto-index [i]
  (def panes (shell-panes))
  (when (< i (length panes))
    (switch-to (get panes i))))

(defn- goto-delta [delta]
  (def panes (shell-panes))
  (def i (index-of (pane/current) panes))
  (when i
    (goto-index (mod (+ i delta) (length panes)))))

(key/action
  action/show-tabs
  "Redraw the tab bar from the current titles."
  (def current (pane/current))
  (if (index-of current (shell-panes))
    (draw-tabs current)
    (msg/toast :warn "not in a shell")))

(key/action
  action/show-carryover
  "Read the full text of the open carryover items."
  (def items (carryover-open))
  (if (empty? items)
    (msg/toast :info "nothing carrying over")
    (input/find
      (seq [item :in items]
        (tuple [(string (get item :line)) (clip (get item :text) 60)]
               {:type :text :text (preview-text (get item :text))}
               item))
      :prompt "search: carryover"
      :headers ["line" "item"])))

(key/action
  action/label-shell
  "Pin a label on the current shell, overriding its title."
  (def pane (pane/current))
  (def current (or (param/get :shell-label :target pane) (tree/name pane)))
  (as?-> (input/text "label this shell (empty to go back to the title):"
                     :preset current) _
         (do (param/set pane :shell-label _)
             (tree/set-name pane (sanitize _))
             (draw-tabs pane))))

(key/action
  action/unlabel-shell
  "Drop the pinned label and go back to the terminal title."
  (def pane (pane/current))
  (param/set pane :shell-label nil)
  (draw-tabs pane))

(key/action
  action/new-shell-here
  "Create a shell in the current directory."
  (def [ok cwd] (protect (cmd/path (pane/current))))
  (def path (if ok cwd (os/getenv "HOME" "")))
  (switch-to (cmd/new (shells) :path path :name (path/base path))))

(key/action
  action/jump-labelled-shell
  "Jump to a shell by its label or by what is running in it."
  (as?-> (shell-panes) _
         (map |(tuple [(tree/name $) (title-of $)] {:type :node :id $} $) _)
         (input/find _
                     :prompt "search: shell"
                     :headers ["shell" "running"]
                     :reverse true)
         (switch-to _)))

(key/action
  action/kill-shell
  "Kill the current shell and move to its neighbour."
  (def pane (pane/current))
  (def panes (shell-panes))
  (def i (index-of pane panes))
  (cond
    (nil? i) (msg/toast :warn "not in a shell")
    (= 1 (length panes)) (msg/toast :warn "that is the last shell")
    (input/ok? (string "kill " (tree/name pane) "?"))
    (do
      # Move first: removing the node you are attached to leaves nowhere to land.
      (def neighbour (get panes (if (= i (dec (length panes))) (dec i) (inc i))))
      (pane/attach neighbour)
      (tree/rm pane)
      (draw-tabs neighbour))))

(key/action
  action/last-shell
  "Return to the shell you came from."
  (pane/history-backward)
  (action/show-tabs))

(key/action
  action/next-shell
  "Move to the next shell."
  (goto-delta 1))

(key/action
  action/prev-shell
  "Move to the previous shell."
  (goto-delta -1))

(key/bind-many-tag :root "shells"
                   [prefix "o"] action/show-carryover
                   [prefix ","] action/label-shell
                   [prefix "."] action/unlabel-shell
                   [prefix "j"] action/new-shell-here
                   [prefix ";"] action/jump-labelled-shell
                   [prefix "l"] action/jump-labelled-shell
                   [prefix "T"] action/show-tabs
                   [prefix "X"] action/kill-shell
                   [prefix "ctrl+o"] action/last-shell)

(key/bind-many-tag :root "unprefixed"
                   ["ctrl+l"] action/next-shell
                   ["alt+o"] action/last-shell)

# A prefixed pair for stepping either way, since ctrl+l only goes forward.
(key/bind-many-tag :root "shells"
                   [prefix "["] action/prev-shell
                   [prefix "]"] action/next-shell)

# <prefix><n> and alt+<n> both go straight to the nth shell, matching the number
# in the tab bar. kitty on macOS only sends alt when macos_option_as_alt is set,
# so the prefixed form is the one that always works.
(loop [i :range [0 9]]
  (def n (string (+ i 1)))
  (def jump (fn [] (goto-index i)))
  (key/bind :root [prefix n] jump)
  (key/bind :root [(string "alt+" n)] jump))
