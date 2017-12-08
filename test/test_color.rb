# encoding: utf-8
require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestColor < Premailer::TestCase

  Color = Premailer::Color

  def test_parse_hex_code
    assert_same_rgb r:255,g:255,b:255,a:1.0, color: Color.parse("#FFFFFF")
    assert_same_rgb r:255,g:255,b:255,a:1.0, color: Color.parse("#ffffff")
    assert_same_rgb r:255,g:255,b:255,a:1.0, color: Color.parse("#fff")
    assert_same_rgb r:255,g:255,b:255,a:1.0, color: Color.parse("#fff")
    assert_same_rgb r:0,  g:0,  b:0,  a:1.0, color: Color.parse("#000000")
    assert_same_rgb r:121,g:171,b:232,a:1.0, color: Color.parse("#79abe8")
    assert_same_rgb r:21, g:211,b:72, a:1.0, color: Color.parse("15d348")
  end

  def test_parse_rgb_code
    assert_same_rgb r:255,g:255,b:255,a:1.0, color: Color.parse("rgb(255, 255, 255)")
    assert_same_rgb r:255,g:255,b:255,a:1.0, color: Color.parse("rgb(255,255,255)")
    assert_same_rgb r:0,  g:0,  b:0,  a:1.0, color: Color.parse("rgb(0, 0, 0)")
    assert_same_rgb r:255,g:186,b:41, a:1.0, color: Color.parse("rgb(255, 186, 41)")
  end

  def test_parse_rgba_code
    assert_same_rgb r:255,g:255,b:255,a:0.86, color: Color.parse("rgba(255, 255, 255, 0.86)")
    assert_same_rgb r:255,g:255,b:255,a:0.86, color: Color.parse("rgba(255, 255, 255, .86)")
    assert_same_rgb r:255,g:255,b:255,a:0.7777, color: Color.parse("rgba(255, 255, 255, 0.7777)")
    assert_same_rgb r:255,g:255,b:255,a:0,    color: Color.parse("rgba(255, 255, 255, 0)")
    assert_same_rgb r:180,g:180,b:180,a:0.55, color: Color.parse("rgba(180, 180, 180, 0.55)")
  end

  def test_to_s
    assert_equal "#FFFFFF",     Color.parse("rgba(255, 255, 255, 0.86)").to_s
    assert_equal "#000000",     Color.parse("#000000").to_s
    assert_equal "#64CF00",     Color.parse("rgba(100, 207, 0, 0.73)").to_s
    assert_equal "#00D1D5",     Color.parse("rgb(0, 209, 213)").to_s
    assert_equal "red",         Color.parse("red").to_s
    assert_equal "transparent", Color.parse("transparent").to_s
  end

  def test_blending_with_other_color
    color = Color.parse("rgba(48, 199, 255, 0.55)")
    background = Color.parse("rgb(255, 255, 255)")
    assert_equal "#8DE0FF", color.blend(background).to_s

    color = Color.parse("rgba(48, 199, 255, 0.55)")
    background = Color.parse("rgb(0, 0, 0)")
    assert_equal "#1A6D8C", color.blend(background).to_s

    color = Color.parse("rgba(48, 199, 255, 0.55)")
    background = Color.parse("rgb(99, 134, 255)")
    assert_equal "#47AAFF", color.blend(background).to_s

    color = Color.parse("rgba(93, 89, 226, 0.7)")
    background = Color.parse("rgb(53, 175, 177)")
    assert_equal "#5173D3", color.blend(background).to_s

    color = Color.parse("rgba(2, 0, 75, 0.4)")
    background = Color.parse("rgb(101, 255, 231)")
    assert_equal "#3D99A9", color.blend(background).to_s

    color = Color.parse("rgba(255, 182, 27, 0.8)")
    background = Color.parse("#6386ff")
    assert_equal "#E0AC49", color.blend(background).to_s

    color = Color.parse("rgba(5, 187, 0, 0.55)")
    background = "#6386ff"
    assert_equal "#2FA373", color.blend(background).to_s
  end

  def test_blending_with_named_color
    blended_to_default_background_white = "#8E8BEB"
    color = Color.parse("rgba(93, 89, 226, 0.7)")
    background = Color.parse("PapayaWhip")
    assert_equal blended_to_default_background_white, color.blend(background).to_s

    color = Color.parse("GhostWhite")
    background = Color.parse("rgb(143, 0, 155)")
    assert_equal "GhostWhite", color.blend(background).to_s
  end

  def test_blending_with_transparent_color
    color = Color.parse("transparent")
    background = Color.parse("rgb(228, 217, 122)")
    assert_equal "#E4D97A", color.blend(background).to_s

    color = Color.parse("rgba(24, 104, 178, 0.6)")
    background = Color.parse("transparent")
    error = assert_raises(ArgumentError) { color.blend(background).to_s }
    assert_equal error.message, "Expected opaque background color"
  end

  def assert_same_rgb(r:,g:,b:,a:,color:)
    assert_equal [r,g,b,a], [color.r,color.g,color.b,color.a]
  end

end
