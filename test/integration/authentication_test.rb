require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "visitors are redirected to login from both dashboard URLs" do
    [ root_path, dashboard_path ].each do |path|
      get path
      assert_redirected_to new_user_session_path
    end
  end

  test "login form is localized and exposes only email and password" do
    get new_user_session_path
    assert_response :success
    assert_select "html[lang='pt-BR']"
    assert_select "label", text: "E-mail"
    assert_select "label", text: "Senha"
    assert_select "input[type=submit][value=ENTRAR]"
    assert_select "a[href*='sign_up']", count: 0
    assert_select "input[name='user[remember_me]']", count: 0
  end

  test "correct credentials sign in and logout protects the dashboard again" do
    post user_session_path, params: { user: { email: users(:admin).email, password: "SenhaDeTeste123!" } }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
    assert_select "h1", text: "Dashboard"
    assert_select "[role=status]", text: "Login realizado com sucesso."
    assert_select "article", count: 6
    assert_select "[aria-disabled=true]", count: 0
    assert_select "nav a", text: "Relatórios"

    delete destroy_user_session_path
    assert_redirected_to new_user_session_path
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "invalid Turbo login gives a localized error without authenticating" do
    post user_session_path,
      params: { user: { email: users(:admin).email, password: "errada" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
    assert_response :unprocessable_content
    assert_select "[role=alert]", text: "E-mail ou senha inválidos."
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "locks the account after repeated failures and unlocks with time" do
    5.times do
      post user_session_path, params: { user: { email: users(:admin).email, password: "errada" } }
      assert_response :unprocessable_content
    end
    assert users(:admin).reload.access_locked?

    post user_session_path, params: { user: { email: users(:admin).email, password: "SenhaDeTeste123!" } }
    assert_response :unprocessable_content
    assert_select "[role=alert]", text: "Sua conta está bloqueada."

    travel_to 31.minutes.from_now do
      post user_session_path, params: { user: { email: users(:admin).email, password: "SenhaDeTeste123!" } }
      assert_redirected_to dashboard_path
    end
  end

  test "expires idle sessions" do
    post user_session_path, params: { user: { email: users(:admin).email, password: "SenhaDeTeste123!" } }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success

    # O login define last_request_at para agora. Avança 31 minutos (acima do timeout de 30 min).
    # O FailureApp do Devise redireciona o GET expirado de volta à página
    # tentada e, em seguida, para /entrar com a mensagem de expiração.
    travel_to 31.minutes.from_now do
      get dashboard_path
      assert_redirected_to dashboard_path
      follow_redirect!
      assert_redirected_to new_user_session_path
      follow_redirect!
      assert_select "[role=alert]", text: "Sua sessão expirou. Entre novamente para continuar."
    end
  end

  test "normalizes email case on save" do
    admin = users(:admin)
    admin.email = "ADMIN@EXAMPLE.TEST"
    assert admin.save
    assert_equal "admin@example.test", admin.reload.email
  end

  test "public registration and password reset routes do not exist" do
    assert_no_difference "User.count" do
      get "/users/sign_up"
      assert_response :not_found
      post "/users", params: { user: { email: "intruso@example.test", password: "SenhaTeste123!" } }
      assert_response :not_found
      get "/users/password/new"
      assert_response :not_found
    end
    assert_equal [ :database_authenticatable, :validatable, :lockable, :timeoutable ], User.devise_modules
  end

  test "health endpoint is public" do
    get rails_health_check_path
    assert_response :success
  end
end
