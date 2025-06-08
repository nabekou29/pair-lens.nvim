-- pair-lens.nvim動作確認用サンプルファイル

-- このファイルを開いてpair-lensプラグインを動作確認してください
-- require("pair-lens").setup() を実行後、このファイルを開くと
-- function、if、for文の終端に開始行の情報が表示されます

function long_function()
  print("This is a long function")

  if true then
    print("Inside if statement")

    for i = 1, 10 do
      print("Loop iteration: " .. i)

      if i % 2 == 0 then
        print("Even number")
      else
        print("Odd number")
      end
    end

    while true do
      print("While loop")
      break
    end
  end

  print("Function end")
end

-- もう一つの関数
function another_function()
  local x = 1
  local y = 2

  do
    local z = x + y
    print("z = " .. z)
  end

  return x + y
end

-- ネストした構造
function nested_example()
  for outer = 1, 3 do
    print("Outer loop: " .. outer)

    for inner = 1, 3 do
      print("  Inner loop: " .. inner)

      if outer == inner then
        print("    Same values!")
      end
    end
  end
end

