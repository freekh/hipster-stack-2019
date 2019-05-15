use actix_web::{web, App, HttpRequest, HttpServer};

fn index(req: HttpRequest) -> &'static str {
    let my_str = include_str!("../build/index.html");

    my_str
}

fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .service(web::resource("/").to(index))
    })
    .bind("127.0.0.1:8080")?
    .run()
}