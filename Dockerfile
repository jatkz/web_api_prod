FROM lukemathwalker/cargo-chef:latest-rust-1.63.0 as chef
WORKDIR /app
RUN apt update && apt install lld clang -y


FROM chef as planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json


FROM chef as builder
COPY --from=planner /app/recipe.json recipe.json
# Build project dependencies, but not the application
RUN cargo chef cook --release --recipe-path recipe.json
# Up to this point caches the very long compile stage
COPY . .
ENV SQLX_OFFLINE true
RUN cargo build --release --bin web_api_prod

FROM debian:bullseye-slim as runtime
WORKDIR /app
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/web_api_prod web_api_prod
COPY configuration configuration
ENV APP_ENVIRONMENT production
EXPOSE 8000
ENTRYPOINT ["./web_api_prod"]