defmodule DemoWeb.PageLive do
  use DemoWeb, :live_view

  def mount(_params, session, socket) do
    {:ok, assign(socket, text: nil, task: nil, result: nil)}
  end

  def handle_event("predict", params, socket) do
    case params["text"] do
      "" ->
        {:noreply, assign(socket, text: nil, task: nil, result: nil)}

      text ->
        task =
          Task.async(fn ->
            Nx.Serving.batched_run(MyServing, text)
          end)

        {:noreply, assign(socket, text: text, task: task, result: nil)}
    end
  end

  def handle_info({ref, result}, socket) when socket.assigns.task.ref == ref do
    [%{label: label, score: _} | _] = result.predictions
    {:noreply, assign(socket, task: nil, result: label)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div>
        <form phx-change="predict">
          <input type="text" name="text" phx-debounce="300" value={@text} />
        </form>
      </div>
      <div>
        <span>Emotion: </span>
        <span><%= @result %></span>
        <span :if={@task}>...Loading</span>
      </div>
    </div>
    """
  end
end
