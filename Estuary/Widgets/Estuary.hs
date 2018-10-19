{-# LANGUAGE RecursiveDo, JavaScriptFFI #-}

module Estuary.Widgets.Estuary where

import Reflex
import Reflex.Dom
import Text.JSON
import Data.Time
import Data.Map
import Text.Read
import Control.Monad.IO.Class (liftIO)
import Control.Concurrent.MVar
import GHCJS.Types
import GHCJS.Marshal.Pure
import Data.Functor (void)

import Estuary.Tidal.Types
import Estuary.Protocol.Foreign
import Estuary.Widgets.Navigation
import Estuary.WebDirt.SampleEngine
import Estuary.WebDirt.WebDirt
import Estuary.WebDirt.SuperDirt
import Estuary.Widgets.WebSocket
import Estuary.Types.Request
import Estuary.Types.Response
import Estuary.Types.Context
import Estuary.Widgets.LevelMeters
import Estuary.Widgets.Terminal
import Estuary.Reflex.Utility
import Estuary.Types.Language
import qualified Estuary.Types.Term as Term
import Estuary.RenderState

estuaryWidget :: MonadWidget t m => MVar Context -> MVar RenderState -> EstuaryProtocolObject -> Context -> m ()
estuaryWidget ctxM rsM protocol ic = divClass "estuary" $ mdo
  -- mapDyn renderErrors ctx >>= display
  headerChanges <- header ctx
  (values,deltasUp,hints) <- divClass "page" $ navigation (startTime ic) ctx commands deltasDown'
  commands <- divClass "chat" $ terminalWidget ctx deltasUp deltasDown'
  (deltasDown,wsStatus) <- alternateWebSocket protocol (startTime ic) deltasUp
  let definitionChanges = fmap setDefinitions $ updated values
  let deltasDown' = ffilter (not . Prelude.null) deltasDown
  let ccChange = fmap setClientCount $ fmapMaybe justServerClientCount deltasDown'
  -- renderStateChanges <- pollRenderStateChanges rsM
  let contextChanges = mergeWith (.) [definitionChanges,headerChanges,ccChange {- ,renderStateChanges -} ]
  ctx <- foldDyn ($) ic contextChanges -- Dynamic t Context
  t <- mapDyn theme ctx -- Dynamic t String
  let t' = updated t -- Event t String
  changeTheme t'
  updateContext ctxM ctx
  performHint (webDirt ic) hints

updateContext :: MonadWidget t m => MVar Context -> Dynamic t Context -> m ()
updateContext cMvar cDyn = performEvent_ $ fmap (liftIO . void . swapMVar cMvar) $ updated cDyn

pollRenderStateChanges :: MonadWidget t m => MVar RenderState -> m (Event t ContextChange)
pollRenderStateChanges rsMvar = do
  now <- liftIO $ getCurrentTime
  rsInitial <- liftIO $ readMVar rsMvar
  ticks <- tickLossy (0.104::NominalDiffTime) now
  newState <- performEvent $ fmap (liftIO . const (readMVar rsMvar)) ticks
  return $ fmap setRenderErrors newState

changeTheme :: MonadWidget t m => Event t String -> m ()
changeTheme newStyle = performEvent_ $ fmap (liftIO . js_setThemeHref . pToJSVal) newStyle

foreign import javascript safe
  "document.getElementById('estuary-current-theme').setAttribute('href', $1);"
  js_setThemeHref :: JSVal -> IO ()

header :: (MonadWidget t m) => Dynamic t Context -> m (Event t ContextChange)
header ctx = divClass "header" $ do
  tick <- getPostBuild
  hostName <- performEvent $ fmap (liftIO . (\_ -> getHostName)) tick
  port <- performEvent $ fmap (liftIO . (\_ -> getPort)) tick
  hostName' <- holdDyn "" hostName
  port' <- holdDyn "" port
  divClass "logo" $ dynText =<< translateDyn Term.EstuaryDescription ctx
  wsStatus' <- mapDyn wsStatus ctx
  clientCount' <- mapDyn clientCount ctx
  statusMsg <- combineDyn f wsStatus' clientCount'
  divClass "server" $ do
    text "server: "
    dynText hostName'
    text ":"
    dynText port'
    text ": "
    dynText statusMsg
  clientConfigurationWidgets ctx
  where
    f "connection open" c = "(" ++ (show c) ++ " clients)"
    f x _ = x


clientConfigurationWidgets :: (MonadWidget t m) => Dynamic t Context -> m (Event t ContextChange)
clientConfigurationWidgets ctx = divClass "webDirt" $ divClass "webDirtMute" $ do
  let styleMap =  fromList [("classic.css", "Classic"),("inverse.css","Inverse")]
  translateDyn Term.Theme ctx >>= dynText
  styleChange <- _dropdown_change <$> dropdown "classic.css" (constDyn styleMap) def -- Event t String
  let styleChange' = fmap (\x c -> c {theme = x}) styleChange -- Event t (Context -> Context)
  translateDyn Term.Language ctx >>= dynText
  let langMap = constDyn $ fromList $ zip languages (fmap show languages)
  langChange <- _dropdown_change <$> (dropdown English langMap def)
  let langChange' = fmap (\x c -> c { language = x }) langChange
  text "SuperDirt:"
  sdInput <- checkbox False $ def
  let sdOn = fmap (\x -> (\c -> c { superDirtOn = x } )) $ _checkbox_change sdInput
  text "WebDirt:"
  wdInput <- checkbox True $ def
  let wdOn = fmap (\x -> (\c -> c { webDirtOn = x } )) $ _checkbox_change wdInput
  return $ mergeWith (.) [langChange',sdOn,wdOn, styleChange']
