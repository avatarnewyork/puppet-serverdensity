require 'facter'
Facter.add(:serverdensity_key) do
  setcode do
    Facter::Util::Resolution.exec('cat /etc/serverdensity.key')
  end
end
