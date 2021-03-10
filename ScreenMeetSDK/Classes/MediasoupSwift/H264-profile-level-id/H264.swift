//
//  H264ProfileLevelId.swift
//  ScreenMeet
//
//  Created by Ross on 28.01.2021.
//

import UIKit

// Map containting SDP codec parameters.
typealias CodecParameterMap = [String: String]

class H264: NSObject {
    
    private static let kProfileLevelId = "profile-level-id"
    private static let kLevelAsymmetryAllowed = "level-asymmetry-allowed";
    // For level_idc=11 and profile_idc=0x42, 0x4D, or 0x58, the constraint set3
    // flag specifies if level 1b or level 1.1 is used.
    private static let constraintSet3Flag: UInt8 = 0x10
    
    // All values are equal to ten times the level number, except level 1b which is
    // special.
    enum Level: UInt8 {
        case kLevel1_b = 0
        case kLevel1 = 10
        case kLevel1_1 = 11
        case kLevel1_2 = 12
        case kLevel1_3 = 13
        case kLevel2 = 20
        case kLevel2_1 = 21
        case kLevel2_2 = 22
        case kLevel3 = 30
        case kLevel3_1 = 31
        case kLevel3_2 = 32
        case kLevel4 = 40
        case kLevel4_1 = 41
        case kLevel4_2 = 42
        case kLevel5 = 50
        case kLevel5_1 = 51
        case kLevel5_2 = 52
    }
    
    enum Profile: UInt8 {
      case kProfileConstrainedBaseline = 1
      case kProfileBaseline = 2
      case kProfileMain = 3
      case kProfileConstrainedHigh = 4
      case kProfileHigh = 5
    }
    
    struct ProfileLevelId {
        let profile: Profile
        let level: Level
    }
    
    private static let kProfilePatterns: [ProfilePattern] =
        [ProfilePattern(profile_idc: 0x4D,
                        profile_iop: BitPattern("x1xx0000"),
                            profile: .kProfileConstrainedBaseline),
        ProfilePattern(profile_idc: 0x4D,
                       profile_iop: BitPattern("1xxx0000"),
                           profile: .kProfileConstrainedBaseline),
        ProfilePattern(profile_idc: 0x58,
                       profile_iop: BitPattern("11xx0000"),
                           profile: .kProfileConstrainedBaseline),
        ProfilePattern(profile_idc: 0x42,
                       profile_iop: BitPattern("x0xx0000"),
                           profile: .kProfileBaseline),
        ProfilePattern(profile_idc: 0x58,
                       profile_iop: BitPattern("10xx0000"),
                           profile: .kProfileBaseline),
        ProfilePattern(profile_idc: 0x4D,
                       profile_iop: BitPattern("0x0x0000"),
                           profile: .kProfileMain),
        ProfilePattern(profile_idc: 0x64,
                       profile_iop: BitPattern("00000000"),
                           profile: .kProfileHigh),
        ProfilePattern(profile_idc: 0x64,
                       profile_iop: BitPattern("00001100"),
                           profile: .kProfileConstrainedHigh)]
    
    /**
     * Parse profile level id that is represented as a string of 3 hex bytes
     * contained in an SDP key-value map. A default profile level id will be
     * returned if the profile-level-id key is missing. Nothing will be returned if
     * the key is present but the string is invalid.
     */
    static func parseSdpProfileLevelId(_ params: CodecParameterMap) -> ProfileLevelId? {
        let kDefaultProfileLevelId = ProfileLevelId(profile: .kProfileConstrainedBaseline, level: .kLevel3_1)
        let profileLevelId = params[kProfileLevelId]
        
        if profileLevelId == nil {
            return kDefaultProfileLevelId
        }
        
        return parseProfileLevelId(profileLevelId!)
    }
    
    /**
     * Parse profile level id that is represented as a string of 3 hex bytes.
     * Nothing will be returned if the string is not a recognized H264 profile
     * level id.
     * */
    
    private static func parseProfileLevelId(_ str: String) -> ProfileLevelId? {
        
        // The string should consist of 3 bytes in hexadecimal format.
        if str.count != 6 {
            return nil
        }
        
        let profile_level_id_numeric = UInt32(str, radix: 16)!
        if profile_level_id_numeric == 0 {
            return nil
        }
        
        // Separate into three bytes.
        let level_idc: UInt8 = UInt8(truncatingIfNeeded: profile_level_id_numeric)
        let profile_iop: UInt8 = UInt8(truncatingIfNeeded: profile_level_id_numeric >> 8)
        let profile_idc: UInt8 = UInt8(truncatingIfNeeded: profile_level_id_numeric >> 16)
        
        var level: Level
        
        switch level_idc {
        case Level.kLevel1_b.rawValue:
                level = (profile_iop & constraintSet3Flag) != 0 ? Level.kLevel1_b : Level.kLevel1_1
    
        case Level.kLevel1.rawValue,
             Level.kLevel1_2.rawValue,
             Level.kLevel1_3.rawValue,
             Level.kLevel2.rawValue,
             Level.kLevel2_1.rawValue,
             Level.kLevel2_2.rawValue,
             Level.kLevel3.rawValue,
             Level.kLevel3_1.rawValue,
             Level.kLevel3_2.rawValue,
             Level.kLevel4.rawValue,
             Level.kLevel4_1.rawValue,
             Level.kLevel4_2.rawValue,
             Level.kLevel5.rawValue,
             Level.kLevel5_1.rawValue,
             Level.kLevel5_2.rawValue:
                level = H264.Level(rawValue: level_idc)!
        default:
                NSLog("parseProfileLevelId() | unrecognized level_idc: " + String(level_idc))
                return nil
        }
        
        // Parse profile_idc/profile_iop into a Profile enum.
        for pattern in kProfilePatterns {
            if (profile_idc == pattern.profile_idc && pattern.profile_iop.isMatch(profile_iop)) {
                return ProfileLevelId(profile: pattern.profile, level: level)
            }
        }
        
        return nil
    }
    
    /**
     * Generate codec parameters that will be used as answer in an SDP negotiation
     * based on local supported parameters and remote offered parameters. Both
     * local_supported_params and remote_offered_params represent sendrecv media
     * descriptions, i.e they are a mix of both encode and decode capabilities. In
     * theory, when the profile in local_supported_params represent a strict superset
     * of the profile in remote_offered_params, we could limit the profile in the
     * answer to the profile in remote_offered_params.
     *
     * However, to simplify the code, each supported H264 profile should be listed
     * explicitly in the list of local supported codecs, even if they are redundant.
     * Then each local codec in the list should be tested one at a time against the
     * remote codec, and only when the profiles are equal should this function be
     * called. Therefore, this function does not need to handle profile intersection,
     * and the profile of local_supported_params and remote_offered_params must be
     * equal before calling this function. The parameters that are used when
     * negotiating are the level part of profile-level-id and level-asymmetry-allowed.
     *
     * @param {CodecParameterMap} [localSupportedParams=[String: String]]
     * @param {CodecParameterMap} [remoteOfferedParams=[Srting: String]]
     *
     *
     */
    // Set level according to https://tools.ietf.org/html/rfc6184#section-8.2.2.
    static func generateProfileLevelIdForAnswer(_ localSupportedParams: CodecParameterMap,
                                         _ remoteOfferedParams: CodecParameterMap) -> CodecParameterMap? {
        
        if localSupportedParams[kProfileLevelId] != remoteOfferedParams[kProfileLevelId] {
            return nil
        }
        
        let local_profile_level_id = parseSdpProfileLevelId(localSupportedParams)
        let remote_profile_level_id = parseSdpProfileLevelId(remoteOfferedParams)
        
        // The local and remote codec must have valid and equal H264 Profiles.
        if (local_profile_level_id == nil) {
               return nil
        }

        if (remote_profile_level_id == nil) {
            return nil
        }

        if (local_profile_level_id!.profile != remote_profile_level_id!.profile) {
            return nil
        }
            
        let level_asymmetry_allowed = isLevelAsymmetryAllowed(localSupportedParams) && isLevelAsymmetryAllowed(remoteOfferedParams)
        
        let local_level: Level = local_profile_level_id!.level
        let remote_level: Level = remote_profile_level_id!.level
        let min_level: Level = Level(rawValue: min(local_level.rawValue, remote_level.rawValue))!
        
        let answer_level: Level = level_asymmetry_allowed ? local_level : min_level;

        var answerParams = CodecParameterMap()
        
        answerParams[kProfileLevelId] = profileLevelIdToString(ProfileLevelId(profile: local_profile_level_id!.profile, level: answer_level))
        
        return answerParams
    }
    
    static func profileLevelIdToString(_ profile_level_id: ProfileLevelId) -> String? {
        // Handle special case level == 1b.
        if (profile_level_id.level == .kLevel1_b) {
          switch (profile_level_id.profile) {
          case Profile.kProfileConstrainedBaseline:
              return "42f00b"
          case Profile.kProfileBaseline:
              return "42100b"
          case Profile.kProfileMain:
              return "4d100b"
            // Level 1b is not allowed for other profiles.
            default:
              return nil
          }
        }
        
        let profile_idc_iop_string: String!
        
        switch (profile_level_id.profile) {
        case Profile.kProfileConstrainedBaseline:
            profile_idc_iop_string = "42e0"
            break
        case Profile.kProfileBaseline:
            profile_idc_iop_string = "4200"
            break
        case Profile.kProfileMain:
            profile_idc_iop_string = "4d00"
            break
        case Profile.kProfileConstrainedHigh:
            profile_idc_iop_string = "640c"
            break
        case Profile.kProfileHigh:
            profile_idc_iop_string = "6400"
            break
        }
        
        let levelStr = String(format:"%02X", profile_level_id.level.rawValue)
        return profile_idc_iop_string+levelStr
    }

    
    static func isSameH264Profile(_ params1: CodecParameterMap, _ params2: CodecParameterMap) -> Bool {
        let profile_level_id = parseSdpProfileLevelId(params1)
        let other_profile_level_id = parseSdpProfileLevelId(params2)
        
        return (profile_level_id != nil && other_profile_level_id != nil) &&
            profile_level_id!.profile == other_profile_level_id!.profile
    }
    
    static func isLevelAsymmetryAllowed(_ params: CodecParameterMap) -> Bool {
        if let asymmetryAllowed = params[kLevelAsymmetryAllowed]{
            if asymmetryAllowed == "1" {
                return true
            }
        }
        
        if let asymmetryAllowed = params[kLevelAsymmetryAllowed] {
            if asymmetryAllowed == "1" {
                return true
            }
        }
        
        return false
    }
    
    private struct ProfilePattern {
        var profile_idc: UInt8
        var profile_iop: BitPattern
        var profile: Profile
    }
    
    private struct BitPattern {
        init(_ str: String) {
            self.mask_ = ~byteMaskString("x", str)
            self.masked_value_ = byteMaskString("1", str)
        }
        var mask_: UInt8!
        var masked_value_: UInt8!
        
        // Convert a string of 8 characters into a byte where the positions containing
        // character c will have their bit set. For example, c = 'x', str = "x1xx0000"
        // will return 0b10110000. constexpr is used so that the pattern table in
        // kProfilePatterns is statically initialized.
        private func byteMaskString(_ c: String, _ str: String) -> UInt8 {
            let result: UInt8 = (str[0] == c ? 1 : 0) << 7
                                | (str[1] == c ? 1 : 0) << 6
                                | (str[2] == c ? 1 : 0) << 5
                                | (str[3] == c ? 1 : 0) << 4
                                | (str[4] == c ? 1 : 0) << 3
                                | (str[5] == c ? 1 : 0) << 2
                                | (str[6] == c ? 1 : 0) << 1
                                | (str[7] == c ? 1 : 0) << 0
            return result
        }
        
        func isMatch(_ value: UInt8) -> Bool {
            return self.masked_value_ == (value & self.mask_)
        }
    }
}


