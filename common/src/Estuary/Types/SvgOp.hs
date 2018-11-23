module Estuary.Types.SvgOp where

import Estuary.Types.Color

data LineCap = Butt | Square | RoundCap deriving (Eq)

instance Show LineCap where
  show Butt = "butt"
  show Square = "square"
  show RoundCap = "round"

data LineJoin = Miter | RoundJoin | Bevel deriving (Eq)

instance Show LineJoin where
  show Miter = "miter"
  show RoundJoin = "round"
  show Bevel = "bevel"

data Stroke = Stroke {
  strokeColor :: Color,
  strokeWidth :: Double,
  strokeLineCap :: LineCap,
  strokeLineJoin :: LineJoin
  } deriving (Show,Eq)

data SvgOp =
  Line Double Double Double Double Stroke |
  Rect Double Double Double Double Stroke
  deriving (Show,Eq)
