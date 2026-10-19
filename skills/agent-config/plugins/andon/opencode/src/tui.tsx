import { Plugin } from "@opencode/plugin/tui";
import { createEffect } from "solid-js";
import { setupBoard } from "./board.ts";
import type { Snapshot } from "./types.ts";

export default Plugin.define({
  id: "andon",
  async setup(context) {
    const [state, update] = context.storage.memory<{
      snapshot: Snapshot | null;
      error: string;
    }>("status", {
      initial: { snapshot: null, error: "" }
    });
    const board = await setupBoard(context, (snapshot, error) => {
      update((draft) => {
        draft.snapshot = snapshot;
        draft.error = error;
      });
    });
    const removeWatcher = context.ui.slot({
      append: "app",
      render: () => {
        createEffect(() => {
          context.ui.router.current();
          void board.refresh();
        });
        return null;
      }
    });
    const render = () => (
      <text fg={context.theme.text.muted}>
        {state.error
          ? "andon: unavailable"
          : state.snapshot
            ? `andon: L${state.snapshot.level} · ${state.snapshot.stats.open} open · ${state.snapshot.stats.open_red} red`
            : ""}
      </text>
    );
    const removeHome = context.ui.slot({
      append: "home.footer.status",
      render
    });
    const removePrompt = context.ui.slot({
      append: "prompt.footer.status",
      render
    });
    return () => {
      board.cleanup();
      removeWatcher();
      removeHome();
      removePrompt();
    };
  }
});
