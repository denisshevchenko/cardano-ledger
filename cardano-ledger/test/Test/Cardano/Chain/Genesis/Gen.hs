module Test.Cardano.Chain.Genesis.Gen
  ( genCanonicalGenesisData
  , genCanonicalGenesisDelegation
  , genGenesisData
  , genGenesisHash
  , genFakeAvvmOptions
  , genGenesisAvvmBalances
  , genGenesisDelegation
  , genGenesisInitializer
  , genGenesisNonAvvmBalances
  , genGenesisSpec
  , genGenesisKeyHashes
  , genSignatureEpochNumber
  , genTestnetBalanceOptions
  )
where

import Cardano.Prelude

import Data.Coerce (coerce)
import qualified Data.Text as T
import Data.Time (UTCTime(..), Day(..), secondsToDiffTime)
import qualified Data.Map.Strict as M
import Formatting (build, sformat)

import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

import Cardano.Chain.Common (BlockCount(..))
import Cardano.Chain.Genesis
  ( FakeAvvmOptions(..)
  , GenesisAvvmBalances(..)
  , GenesisData(..)
  , GenesisDelegation(..)
  , GenesisHash(..)
  , GenesisInitializer(..)
  , GenesisNonAvvmBalances(..)
  , GenesisSpec(..)
  , GenesisKeyHashes(..)
  , TestnetBalanceOptions(..)
  , mkGenesisDelegation
  , mkGenesisSpec
  )
import Cardano.Chain.Slotting (EpochNumber)
import Cardano.Crypto (ProtocolMagicId, Signature(..))
import qualified Cardano.Crypto.Wallet as CC

import Test.Cardano.Chain.Common.Gen
  (genAddress, genBlockCount, genLovelace, genLovelacePortion, genKeyHash)
import Test.Cardano.Chain.Delegation.Gen
  (genCanonicalCertificateDistinctList, genCertificateDistinctList)
import Test.Cardano.Chain.Update.Gen
  (genCanonicalProtocolParameters, genProtocolParameters)
import Test.Cardano.Crypto.Gen
  ( genProtocolMagic
  , genProtocolMagicId
  , genCompactRedeemVerificationKey
  , genTextHash
  )

genCanonicalGenesisData :: ProtocolMagicId -> Gen GenesisData
genCanonicalGenesisData pm =
  GenesisData
    <$> genGenesisKeyHashes
    <*> genCanonicalGenesisDelegation pm
    <*> genUTCTime
    <*> genGenesisNonAvvmBalances
    <*> genCanonicalProtocolParameters
    <*> genBlockCount'
    <*> genProtocolMagicId
    <*> genGenesisAvvmBalances
 where
  genBlockCount' :: Gen BlockCount
  genBlockCount' = BlockCount <$> Gen.word64 (Range.linear 0 1000000000)

genCanonicalGenesisDelegation :: ProtocolMagicId -> Gen GenesisDelegation
genCanonicalGenesisDelegation pm =
  mkGenesisDelegation' <$> genCanonicalCertificateDistinctList pm
 where
  mkGenesisDelegation' =
    either (panic . sformat build) identity . mkGenesisDelegation

genGenesisData :: ProtocolMagicId -> Gen GenesisData
genGenesisData pm =
  GenesisData
    <$> genGenesisKeyHashes
    <*> genGenesisDelegation pm
    <*> genUTCTime
    <*> genGenesisNonAvvmBalances
    <*> genProtocolParameters
    <*> genBlockCount
    <*> genProtocolMagicId
    <*> genGenesisAvvmBalances

genGenesisHash :: Gen GenesisHash
genGenesisHash = GenesisHash . coerce <$> genTextHash

genFakeAvvmOptions :: Gen FakeAvvmOptions
genFakeAvvmOptions =
  FakeAvvmOptions <$> Gen.word Range.constantBounded <*> genLovelace

genGenesisDelegation :: ProtocolMagicId -> Gen GenesisDelegation
genGenesisDelegation pm = mkGenesisDelegation' <$> genCertificateDistinctList pm
 where
  mkGenesisDelegation' =
    either (panic . sformat build) identity . mkGenesisDelegation

genGenesisInitializer :: Gen GenesisInitializer
genGenesisInitializer =
  GenesisInitializer
    <$> genTestnetBalanceOptions
    <*> genFakeAvvmOptions
    <*> genLovelacePortion
    <*> Gen.bool
    <*> Gen.integral (Range.constant 0 10)

genGenesisNonAvvmBalances :: Gen GenesisNonAvvmBalances
genGenesisNonAvvmBalances = GenesisNonAvvmBalances . M.fromList <$> Gen.list
  (Range.linear 1 10)
  ((,) <$> genAddress <*> genLovelace)

genGenesisSpec :: ProtocolMagicId -> Gen GenesisSpec
genGenesisSpec pm = either (panic . toS) identity <$> mkGenSpec
 where
  mkGenSpec =
    mkGenesisSpec
      <$> genGenesisAvvmBalances
      <*> genGenesisDelegation pm
      <*> genProtocolParameters
      <*> genBlockCount
      <*> genProtocolMagic
      <*> genGenesisInitializer

genTestnetBalanceOptions :: Gen TestnetBalanceOptions
genTestnetBalanceOptions =
  TestnetBalanceOptions
    <$> Gen.word Range.constantBounded
    <*> Gen.word Range.constantBounded
    <*> genLovelace
    <*> genLovelacePortion

genGenesisAvvmBalances :: Gen GenesisAvvmBalances
genGenesisAvvmBalances =
  GenesisAvvmBalances
    <$> customMapGen genCompactRedeemVerificationKey genLovelace

genGenesisKeyHashes :: Gen GenesisKeyHashes
genGenesisKeyHashes =
  GenesisKeyHashes <$> Gen.set (Range.constant 10 25) genKeyHash

genSignatureEpochNumber :: Gen (Signature EpochNumber)
genSignatureEpochNumber =
  either (panic . T.pack) Signature
    .   CC.xsignature
    <$> Gen.utf8 (Range.constant 64 64) Gen.hexit

genUTCTime :: Gen UTCTime
genUTCTime
  = (\jday seconds ->
      UTCTime (ModifiedJulianDay jday) (secondsToDiffTime seconds)
    )
    <$> Gen.integral (Range.linear 0 1000000)
    <*> Gen.integral (Range.linear 0 86401)

--------------------------------------------------------------------------------
-- Helper Generators
--------------------------------------------------------------------------------

customMapGen :: Ord k => Gen k -> Gen v -> Gen (Map k v)
customMapGen keyGen valGen =
  M.fromList <$> Gen.list (Range.linear 1 10) ((,) <$> keyGen <*> valGen)
