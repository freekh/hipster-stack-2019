use serde::{Deserialize, Serialize};
use actix_web::{web, App, Responder, HttpServer};
use web::{Json, post};

 #[derive(Deserialize, Serialize, Clone)]
enum Direction {
  North, West, South, East,
}

 #[derive(Deserialize, Serialize, Clone)]
struct Pos {
  x: usize,
  y: usize,
}

#[derive(Deserialize, Serialize, Clone)]
struct State {
  pos: Pos,
  dir: Direction,
  matrix: Vec<Vec<bool>>,
}

fn next(json: Json<State>) -> impl Responder {
  let Json(state) = json;
  let pos = state.pos;
  let cell = state.matrix[pos.y][pos.x];
  let (next_pos, next_dir) = match (state.dir, cell) {
    // white
    (Direction::North, false) => (Pos { x: pos.x + 1, ..pos }, Direction::East),
    (Direction::East, false) => (Pos { y: pos.y + 1, ..pos }, Direction::South),
    (Direction::South, false) => (Pos { x: pos.x - 1, ..pos }, Direction::West),
    (Direction::West, false) => (Pos { y: pos.y - 1, ..pos }, Direction::North),
    // black
    (Direction::North, true) => (Pos { x: pos.x - 1, ..pos }, Direction::West),
    (Direction::East, true) => (Pos { y: pos.y - 1, ..pos }, Direction::North),
    (Direction::South, true) => (Pos { x: pos.x + 1, ..pos }, Direction::East),
    (Direction::West, true) => (Pos { y: pos.y + 1, ..pos }, Direction::South),
  };
  Json(State {
    pos: next_pos,
    dir: next_dir,
    matrix: {
      let m = &mut state.matrix.clone();
      let cell = &mut m[pos.y][pos.x];
      *cell = !*cell;
      m.clone()
    }
  })
}

fn main() -> std::io::Result<()> {
  HttpServer::new(|| App::new().service(
    web::resource("/next").route(post().to(next)))
  ).bind("127.0.0.1:8080")?
  .run()
}
