use web_api_prod::run;

#[tokio::main]
async fn main() -> std::io::Result<()> {
    run()?.await
}
