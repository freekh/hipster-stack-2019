module Main where

import Affjax (post)
import Data.Tuple.Nested ((/\))
import Effect.Aff (Aff, Milliseconds(..), delay, runAff_, throwError)
import Effect.Class (liftEffect)
import Graphics.Canvas

import Affjax.RequestBody (RequestBody(..))
import Affjax.ResponseFormat (json)
import Data.Argonaut.Decode (decodeJson)
import Data.Argonaut.Encode (encodeJson)
import Data.Array (length)
import Data.Either (Either(..), either)
import Data.Foldable (foldl)
import Data.FoldableWithIndex (traverseWithIndex_)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Exception (throwException, error)
import Prelude (Unit, bind, const, discard, flip, map, max, pure, unit, ($), (*), (/), (<<<))
import Record (merge)

type State = Array (Array Boolean)

init :: State
init = [ [false, false, true , false, false]
       , [true , false, true , false, false]
       , [false, false, true , true , false]
       , [false, true , false, false, false]
       , [false, false, false, true , false]
       ]

render :: Context2D -> Dimensions -> State -> Aff Unit
render ctx dims rows = liftEffect $ do
  clearRect ctx { x: 0.0, y: 0.0, height: dims.height, width: dims.width }
  traverseWithIndex_ renderRow rows
  where
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
    colsLength = foldl (flip $ max <<< (toNumber <<< length)) 0.0 rows
  

update :: State -> Aff State
update world = do
  res <- post json "/api" $ Json $ encodeJson world
  case map decodeJson res.body  of
    Right (Right nextWorld) -> pure $ nextWorld
    _ -> throwError $ error "Wat iz going on?"

run :: forall x. Aff x -> Effect Unit
run = runAff_ (either throwException $ const (pure unit))

main :: Effect Unit
main = run $ do
  (ctx /\ dims) <- liftEffect $ do
    maybeElem <- getCanvasElementById "gol"
    case maybeElem of
      Nothing -> throwException $ error "Wat. Iz. Goyng. Oooon!?!?!?#@#"
      Just elem -> do
        ctx <- getContext2D elem
        dims <- getCanvasDimensions elem
        pure $ ctx /\ dims
  loop ctx dims init
    where
      loop ctx dims world = do
        nextWorld <- update world
        render ctx dims nextWorld
        delay (Milliseconds 1000.0)
        loop ctx dims nextWorld

    