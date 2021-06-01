defmodule ShlinkedinWeb.HomeLiveTest do
  use ShlinkedinWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Shlinkedin.Timeline

  setup :register_user_and_profile

  @create_attrs %{
    body: "some body"
  }

  test "initial render with user and profile", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live("/home")

    assert render(view) =~ "Start a post"
  end

  describe "Index" do
    test "create new post and lists them", %{conn: conn, profile: profile} do
      {:ok, post} = Timeline.create_post(profile, @create_attrs, %Timeline.Post{})

      {:ok, _index_live, html} = live(conn, Routes.home_index_path(conn, :index))

      assert html =~ post.body
      assert html =~ "ShlinkNews"
    end

    test "saves new post", %{conn: conn} do
      {:ok, index_live, _html} =
        conn
        |> live(Routes.home_index_path(conn, :index))

      assert index_live |> element("a", "Start a post") |> render_click() =~
               "Create a post"

      assert_patch(index_live, Routes.home_index_path(conn, :new))

      {:ok, _, html} =
        index_live
        |> form("#post-form", post: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.home_index_path(conn, :index))

      assert html =~ "Post created successfully"
      assert html =~ "some body"
    end

    test "deletes post", %{conn: conn, profile: profile} do
      {:ok, index_live, _html} = live(conn, Routes.home_index_path(conn, :index))

      {:ok, post} = Timeline.create_post(profile, %{body: "test"}, %Timeline.Post{})

      assert index_live |> element("#options-menu-#{post.id}") |> render_click()

      assert index_live |> element("#post-#{post.id} a", "Delete") |> render_click()

      refute index_live
             |> element("#post-#{post.id} a", "Delete")
             |> has_element?()
    end

    # add test for show likes
    # add test for like
    # add test for comment
    test "like post", %{conn: conn, profile: profile} do
      {:ok, index_live, _html} = live(conn, Routes.home_index_path(conn, :index))

      {:ok, post} = Timeline.create_post(profile, %{body: "test"}, %Timeline.Post{})

      assert index_live |> element("#post-#{post.id}-like-Invest") |> render_click()

      assert index_live |> element("#post-likes-#{post.id}") |> render() =~ "1"
    end
  end
end
