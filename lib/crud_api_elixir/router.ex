defmodule CrudApiElixir.Router do
  require Logger
  alias CrudApiElixir.JSONUtils, as: JSON

  # Bring Plug.Router module into scope
  use Plug.Router

  # Attach the Logger to log incoming requests
  plug(Plug.Logger)

  # Tell Plug to match the incoming request with the defined endpoints
  plug(:match)

  # Once there is a match, parse the response body if the content-type
  # is application/json. The order is important here, as we only want to
  # parse the body if there is a matching route.(Using the Jayson parser)
  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  # Dispatch the connection to the matched handler
  plug(:dispatch)

  # Handler for GET request with "/" path
  get "/" do
    send_resp(conn, 200, "OK")
  end

  get "/knockknock" do
    case Mongo.start_link(url: "mongodb://localhost:27017/crud_api_elixir_db") do
      {:ok, _res} -> send_resp(conn, 200, "Who's there?")
      {:error, _err} -> send_resp(conn, 500, "Something went wrong")
    end
  end

  get "/posts" do
     {:ok, top} = Mongo.start_link(url: "mongodb://localhost:27017/crud_api_elixir_db")
    posts =
      Mongo.find(top, "Posts", %{}) # Find all the posts in the database
      |> Enum.map(&JSON.normaliseMongoId/1) # For each of the post normalise the id
      |> Enum.to_list() # Convert the records to a list
      |> Jason.encode!() # Encode the list to a JSON string

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, posts) # Send a 200 OK response with the posts in the body
  end

  post "/post" do
    case Mongo.start_link(url: "mongodb://localhost:27017/crud_api_elixir_db") do
      {:ok, top} ->
        Logger.debug "Connection successful"
        %{"name" => name, "content" => content} = conn.body_params
        Logger.debug "name: #{inspect(name)}"
        Logger.debug "content: #{inspect(content)}"
        Logger.debug "top: #{inspect(top)}"
        Mongo.insert_one(top, "Posts", %{"name" => name, "content" => content})

        posts =
          Mongo.find(top, "Posts", %{}) # Find all the posts in the database
          |> Enum.map(&JSON.normaliseMongoId/1) # For each of the post normalise the id
          |> Enum.to_list() # Convert the records to a list
          |> Jason.encode!() # Encode the list to a JSON string

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, posts) # Send a 200 OK response with the posts in the body
      {:error, _err} ->
        Logger.debug "Connection failed"
        send_resp(conn, 400, "Something went wrong")
    end
  end

  get "/post/:id" do
    case Mongo.start_link(url: "mongodb://localhost:27017/crud_api_elixir_db") do
      {:ok, top} ->
        doc = Mongo.find_one(top, "Posts", %{_id: BSON.ObjectId.decode!(id)})

        case doc do
          nil ->
            send_resp(conn, 404, "Not Found")

          %{} ->
            post =
              JSON.normaliseMongoId(doc)
              |> Jason.encode!()

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, post)

          {:error, _} ->
            send_resp(conn, 500, "Something went wrong")
        end
      {:error, _err} ->
        Logger.debug "Connection failed"
        send_resp(conn, 400, "Something went wrong")
    end
  end

  put "post/:id" do
    {:ok, top} = Mongo.start_link(url: "mongodb://localhost:27017/crud_api_elixir_db")
    case Mongo.find_one_and_update(
           top,
           "Posts",
           %{_id: BSON.ObjectId.decode!(id)},
           %{
             "$set":
               conn.body_params
               |> Map.take(["name", "content"])
               |> Enum.into(%{}, fn {key, value} -> {"#{key}", value} end)
           },
           return_document: :after
         ) do
      {:ok, doc} ->
        case doc do
          nil ->
            send_resp(conn, 404, "Not Found")

          _ ->
            post =
              JSON.normaliseMongoId(doc)
              |> Jason.encode!()

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, post)
        end

      {:error, _} ->
        send_resp(conn, 500, "Something went wrong")
    end
  end

  delete "post/:id" do
    {:ok, top} = Mongo.start_link(url: "mongodb://localhost:27017/crud_api_elixir_db")
    Mongo.delete_one!(top, "Posts", %{_id: BSON.ObjectId.decode!(id)})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{id: id}))
  end

  # Fallback handler when there was no match
  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
