module Estuary.RenderState where

import Data.Time.Clock
import Data.IntMap.Strict
import qualified Sound.Tidal.Context as Tidal
import qualified Sound.Punctual.PunctualW as Punctual

import Estuary.Types.Definition
import Estuary.RenderInfo

data RenderState = RenderState {
  logicalTime :: !UTCTime,
  cachedDefs :: !DefinitionMap,
  paramPatterns :: !(IntMap Tidal.ControlPattern),
  dirtEvents :: ![(UTCTime,Tidal.ControlMap)],
  punctuals :: !(IntMap Punctual.PunctualW),
  renderStartTime :: !UTCTime,
  parseEndTime :: !UTCTime,
  patternsEndTime :: !UTCTime,
  renderEndTime :: !UTCTime,
  renderTimes :: ![NominalDiffTime],
  parseTimes :: ![NominalDiffTime],
  patternsTimes :: ![NominalDiffTime],
  info :: !RenderInfo
  }

initialRenderState :: UTCTime -> RenderState
initialRenderState t = RenderState {
  logicalTime = t,
  cachedDefs = empty,
  paramPatterns = empty,
  dirtEvents = [],
  punctuals = empty,
  renderStartTime = t,
  parseEndTime = t,
  patternsEndTime = t,
  renderEndTime = t,
  renderTimes = [],
  parseTimes = [],
  patternsTimes = [],
  info = emptyRenderInfo
  }
