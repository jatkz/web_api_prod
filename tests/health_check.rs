#[tokio::test]
async fn health_check_works() {
    spawn_app();

    let client = reqwest::Client::new();

    let response = client
        .get("http://127.0.0.1:8000/health_check")
        .send()
        .await
        .expect("Failed to execute request");

    assert!(response.status().is_success());
    assert_eq!(Some(0), response.content_length());
}

fn spawn_app() {
    let server = web_api_prod::run().expect("Failed to bind address");

    // launch the server as background task
    let _ = tokio::spawn(server);
}
