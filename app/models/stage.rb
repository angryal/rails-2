class Stage < ActiveRecord::Base
  belongs_to :balance_in, :class_name => :Balance, :dependent => :destroy
  belongs_to :balance_out, :class_name => :Balance, :dependent => :destroy
  belongs_to :potential, :class_name => :Balance, :dependent => :destroy
  has_many :trades, :dependent => :destroy

  attr_accessible :sequence

  def balance_in_calc
    trades.reduce(Balance.make_usd(0)) do |total, trade|
      trade.balance_in.usd? ? total + trade.balance_in : total
    end
  end

  def balance_usd_out
    trades.reduce(Balance.make_usd(0)) do |total, trade|
      trade.offer.market.to_currency == 'usd' ? total + trade.calculated_out : total
    end
  end

end