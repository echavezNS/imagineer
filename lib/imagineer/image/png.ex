defmodule Imagineer.Image.PNG do
  alias Imagineer.Image

  @png_signiture <<137::size(8), 80::size(8), 78::size(8), 71::size(8),
                   13::size(8),  10::size(8), 26::size(8), 10::size(8)>>
  @ihdr_header <<73::size(8), 72::size(8), 68::size(8), 82::size(8)>>
  @idat_header <<73::size(8), 68::size(8), 65::size(8), 84::size(8)>>
  @iend_header <<73::size(8), 69::size(8), 78::size(8), 68::size(8)>>

  def process(%Image{format: :png, raw: raw}=image) do
    process_header(image, raw)
  end

  def process_header(image, <<@png_signiture, rest::binary>>) do
    process_header(image, rest)
  end


  def process_header(%Image{} = image, <<content_length::size(32), @ihdr_header, content::binary-size(content_length), _crc::size(32), rest::binary>>) do
    <<width::integer-size(32),
      height::integer-size(32), bit_depth::integer,
      color_type::integer, compression::integer, filter_method::integer,
      interface_method::integer>> = content
    header = Map.merge image.header, %{
      color_type: detect_color_type(color_type, bit_depth),
      compression: compression,
      filter_method: filter_method,
      interface_method: interface_method
    }

    image = %Image{ image | header: header, width: width, height: height, bit_depth: bit_depth }
    process_header(image, rest)
  end

  def process_header(%Image{} = image, <<_length::size(32), @iend_header, _rest::binary>>) do
    image
  end

  # There can be multiple IDAT chunks to allow the encoding system to control
  # memory consumption. Append the content
  def process_header(%Image{ header: header } = image, <<content_length::integer-size(32), @idat_header, content::binary-size(content_length), _crc::size(32), rest::binary >>) do
    header = Map.merge header, %{ content: image.content <> content }
    process_header(%Image{ image | header: header }, rest)
  end


  # For headers that we don't understand, skip them
  def process_header(%Image{} = image, <<content_length::size(32), _header::size(32),
      _content::binary-size(content_length), _crc::size(32), rest::binary>>) do
    process_header(image, rest)
  end

  defp detect_color_type(0, 1)  do
    :grayscale1
  end

  defp detect_color_type(0, 2)  do
    :grayscale2
  end

  defp detect_color_type(0, 4)  do
    :grayscale4
  end

  defp detect_color_type(0, 8)  do
    :grayscale8
  end

  defp detect_color_type(0, 16) do
    :grayscale16
  end

  defp detect_color_type(2, 8)  do
    :rgb8
  end

  defp detect_color_type(2, 16) do
    :rgb16
  end

  defp detect_color_type(3, 1)  do
    :palette1
  end

  defp detect_color_type(3, 2)  do
    :palette2
  end

  defp detect_color_type(3, 4)  do
    :palette4
  end

  defp detect_color_type(3, 8)  do
    :palette8
  end

  defp detect_color_type(4, 8)  do
    :grayscale_alpha8
  end

  defp detect_color_type(4, 16) do
    :grayscale_alpha16
  end

  defp detect_color_type(6, 8)  do
    :rgb_alpha8
  end

  defp detect_color_type(6, 16) do
    :rgb_alpha16
  end
end
