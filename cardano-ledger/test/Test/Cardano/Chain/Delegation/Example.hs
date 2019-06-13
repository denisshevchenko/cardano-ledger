module Test.Cardano.Chain.Delegation.Example
  ( exampleCertificates
  )
where

import Cardano.Prelude

import Data.List (zipWith4)

import Cardano.Chain.Delegation (Certificate, mkCertificate)
import Cardano.Chain.Slotting (EpochNumber(..))
import Cardano.Crypto (ProtocolMagicId(..))

import Test.Cardano.Crypto.Example (exampleVerificationKeys, staticSafeSigners)


staticProtocolMagics :: [ProtocolMagicId]
staticProtocolMagics = ProtocolMagicId <$> [0 .. 5]

exampleCertificates :: [Certificate]
exampleCertificates = zipWith4
  mkCertificate
  staticProtocolMagics
  staticSafeSigners
  (exampleVerificationKeys 1 6)
  exampleEpochIndices
  where exampleEpochIndices = EpochNumber <$> [5, 1, 3, 27, 99, 247]
