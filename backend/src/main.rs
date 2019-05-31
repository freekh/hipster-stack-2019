use actix_web::{web, http::header, App, middleware::cors::Cors, HttpRequest, HttpResponse, HttpServer};
use web::{Json, post, resource};

const NEIGHBOURS: [(i64, i64); 8] = [
  ( 1, 1),  ( 1, 0),  ( 1, -1),
  ( 0, 1)/*,( 0, 0)*/,( 0, -1), // skip self
  (-1, 1),  (-1, 0),  (-1, -1)
];

fn count_neighbours(world: &Vec<Vec<bool>>, x: i64, y: i64) -> usize {
  NEIGHBOURS.iter().fold(0, |sum, &(nx, ny)| {
    let x_bound = nx + x;
    let y_bound = ny + y;
    if x_bound >= 0 && y_bound >= 0 {
      let &alive = world
        .get(x_bound as usize)
        .and_then(|row| { row.get(y_bound as usize) })
        .unwrap_or(&false);
      if alive {
        sum + 1
      } else {
        sum
      }
    } else {
      sum
    }
  })
}

fn next(world: Vec<Vec<bool>>) -> Vec<Vec<bool>> {
  world.iter().enumerate().map(|(x, row)| {
    row.iter().enumerate().map(|(y, &alive)| {
      let live_neighbours = count_neighbours(&world, x as i64, y as i64);
      if alive && live_neighbours < 2 {
        false
      } else if alive && (live_neighbours == 2 || live_neighbours == 3) {
        true
      } else if alive && live_neighbours > 3 {
        false
      } else if !alive && live_neighbours == 3 {
        true
      } else {
        alive
      }
    }).collect()
  }).collect()
}

fn api(_req: HttpRequest, data: Json<Vec<Vec<bool>>>) -> HttpResponse {
    HttpResponse::Ok().json(next(data.into_inner()))
}

fn index_html(_req: HttpRequest) -> HttpResponse {
    HttpResponse::Ok().content_type("text/html").body(include_str!("../../frontend/build/index.html"))
}
fn index_js(_req: HttpRequest) -> HttpResponse {
    HttpResponse::Ok().content_type("text/javascript").body(include_str!("../../frontend/build/index.js"))
}

fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .wrap(
                 Cors::new()
                    .allowed_origin("http://localhost:8080")
                    .allowed_methods(vec!["GET", "POST"])
                    .allowed_headers(vec![header::AUTHORIZATION, header::ACCEPT])
                    .allowed_header(header::CONTENT_TYPE)
            )           
            .service(resource("/").to(index_html))
            .service(resource("/index.js").to(index_js))
            .service(resource("/api").route(post().to(api)))
    })
    .bind("127.0.0.1:8080")?
    .run()
}