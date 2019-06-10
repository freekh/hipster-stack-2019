module Main where

import Prelude

import Affjax (post)
import Affjax.RequestBody (RequestBody(..))
import Affjax.ResponseFormat (json)
import Data.Argonaut.Core (jsonEmptyObject)
import Data.Argonaut.Decode (class DecodeJson, decodeJson, (.:))
import Data.Argonaut.Decode.Generic.Rep (decodeLiteralSumWithTransform)
import Data.Argonaut.Encode (class EncodeJson, encodeJson, (:=), (~>))
import Data.Argonaut.Encode.Generic.Rep (encodeLiteralSumWithTransform)
import Data.Array (foldl, length, (..))
import Data.Either (Either(..), either)
import Data.FoldableWithIndex (traverseWithIndex_)
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..), delay, error, runAff_, throwError)
import Effect.Class (liftEffect)
import Effect.Exception (throwException)
import Graphics.Canvas (CanvasImageSource, Context2D, Dimensions, clearRect, drawImageScale, fillRect, getCanvasDimensions, getCanvasElementById, getContext2D, tryLoadImage)
import Record (merge)

data Direction = North | West | South | East

type Pos = { x :: Int, y :: Int }

newtype State = State
  { pos :: Pos
  , dir :: Direction
  , matrix :: Array (Array Boolean)
  }

derive instance genericDirection :: Generic Direction _
instance showDirection:: Show Direction where
  show a = genericShow a
instance encodeJsonDirection :: EncodeJson Direction where
  encodeJson a = encodeLiteralSumWithTransform identity a
instance decodeJsonDirection :: DecodeJson Direction where
  decodeJson a = decodeLiteralSumWithTransform identity a
instance showState:: Show State where
  show (State a) = show a
instance encodeJsonState :: EncodeJson State where
  encodeJson (State s) = do
    "pos" := s.pos 
      ~> "dir" := s.dir
      ~> "matrix" := s.matrix
      ~> jsonEmptyObject
instance decodeJsonState :: DecodeJson State where
  decodeJson json = do
    v <- decodeJson json
    pos <- v .: "pos"
    x <- pos .: "x"
    y <- pos .: "y"
    dir <- v .: "dir"
    matrix <- v .: "matrix"
    pure $ State { pos: { x, y }, dir, matrix }

init :: State
init =
  State { pos: { x: 6, y: 6 }, dir: West, matrix }
  where
    matrix :: Array (Array Boolean)
    matrix = map (const (map (const false) (0..10))) (0..10)

update :: State -> Aff State
update state = do
  res <- post json "/next" $ Json $ encodeJson state
  case map decodeJson res.body  of
    Right (Right nextState) -> pure $ nextState
    _ -> throwError $ error "Wat iz going on?"

run :: forall x. Aff x -> Effect Unit
run = runAff_ (either throwException $ const (pure unit))

render :: Context2D -> Dimensions -> CanvasImageSource -> State -> Aff Unit
render ctx dims antImg (State { pos: { x, y }, dir, matrix: rows }) = liftEffect $ do
  clearRect ctx { x: 0.0, y: 0.0, height: dims.height, width: dims.width }
  traverseWithIndex_ renderRow rows
  renderAnt
  where
    renderAnt :: Effect Unit
    renderAnt =
      drawImageScale ctx antImg 
        (toNumber x * cellDims.width)
        (toNumber y * cellDims.height)
        cellDims.width
        cellDims.height
                
    renderRow :: Int -> Array Boolean -> Effect Unit
    renderRow row cols = traverseWithIndex_ (renderCell row) cols 
    
    renderCell :: Int -> Int -> Boolean  -> Effect Unit
    renderCell row col cell = 
      if cell then fillRect ctx $ merge pos cellDims
      else pure unit
      where pos = { x: toNumber col * cellDims.width
                  , y: toNumber row * cellDims.height
                  }

    cellDims = { width: dims.width / (toNumber $ length rows)
               , height: dims.height / colsLength
               }
  
    colsLength :: Number
    colsLength = foldl (flip $ max <<< toNumber <<< length) 0.0 rows

loop :: Context2D -> Dimensions -> State -> CanvasImageSource -> Aff Unit
loop ctx dims state antImg = do
  render ctx dims antImg state
  nextState <- update state
  delay (Milliseconds 500.0)
  loop ctx dims nextState antImg

main :: Effect Unit
main = do
  maybeElem <- getCanvasElementById "c"
  case maybeElem of
    Just elem -> do
      ctx <- getContext2D elem
      dims <- getCanvasDimensions elem
      tryLoadImage "/ant.png" $ start ctx dims init
    Nothing -> throwError $ error "SHit major tissue!! No canvas?"
  where
    start :: Context2D -> Dimensions -> State -> Maybe CanvasImageSource -> Effect Unit
    start ctx dims state (Just antImg) = run $ loop ctx dims state antImg
    start _ _ _ _ = throwError $ error "Goad damn it! No Image?!"
    
